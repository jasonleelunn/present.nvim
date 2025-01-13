local execution = require("present.execution")
local parsing = require("present.parsing")
local utils = require("present.utils")
local windows = require("present.windows")

local M = {}

local state = {
  config = {
    hide_separator_in_title = true,
    separators = { "^# " },
    keymaps = {
      execute_code_blocks = "X",
      previous_slide = "p",
      next_slide = "n",
      first_slide = "f",
      last_slide = "e",
      end_presentation = "q",
    },
    presentation_vim_options = {
      cmdheight = 0,
      conceallevel = 0,
      hlsearch = false,
      linebreak = true,
      wrap = true,
    },
    executors = {
      go = execution.execute_go_code,
      javascript = execution.create_system_executor("node"),
      lua = execution.execute_lua_code,
      python = execution.create_system_executor("python"),
      rust = execution.execute_rust_code,
    },
  },
  active = false,
  slides = {},
  current_slide = 1,
  floats = {},
}

local function set_slide_content(idx)
  local width = vim.o.columns

  local slide = state.slides[idx]

  local title_padding = string.rep(" ", (width - #slide.title) / 2)
  local title = title_padding .. slide.title
  vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })

  vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)

  local footer = string.format("  %d / %d | %s", state.current_slide, #state.slides, state.title)
  vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
end

local function set_presentation_keymaps()
  local function set_keymap(mode, key, callback)
    vim.keymap.set(mode, key, callback, {
      buffer = state.floats.body.buf,
    })
  end

  local keymaps = state.config.keymaps

  set_keymap("n", keymaps.previous_slide, function()
    state.current_slide = math.max(state.current_slide - 1, 1)
    set_slide_content(state.current_slide)
  end)

  set_keymap("n", keymaps.next_slide, function()
    state.current_slide = math.min(state.current_slide + 1, #state.slides)
    set_slide_content(state.current_slide)
  end)

  set_keymap("n", keymaps.first_slide, function()
    state.current_slide = 1
    set_slide_content(state.current_slide)
  end)

  set_keymap("n", keymaps.last_slide, function()
    state.current_slide = #state.slides
    set_slide_content(state.current_slide)
  end)

  set_keymap("n", keymaps.end_presentation, function()
    M.end_presentation()
  end)

  set_keymap("n", keymaps.execute_code_blocks, function()
    local blocks = state.slides[state.current_slide].blocks
    local execution_results = {}

    for _, block in pairs(blocks) do
      local executor = state.config.executors[block.language]

      table.insert(execution_results, { block = block, output = executor(block) })
    end

    local formatted_output = M.format_execution_output(execution_results)
    windows.create_execution_result_window(formatted_output)
  end)
end

---@param execution_results present.ExecutionResult[]
---@return string[]
M.format_execution_output = function(execution_results)
  local formatted_output = {}

  utils.foreach(execution_results, function(_, result)
    local text = { "", "# Output " .. "(" .. result.block.language .. ")", "" }
    vim.list_extend(text, result.output)
    vim.list_extend(formatted_output, text)
  end)

  return formatted_output
end

---@param opts present.StartOptions | nil
M.start_presentation = function(opts)
  if state.active then
    return
  end

  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  if opts.filepath then
    local file_exists = vim.uv.fs_stat(opts.filepath)

    if not file_exists then
      local error_msg = string.format("present.nvim: Failed to start, file '%s' not found!", opts.filepath)
      vim.notify(error_msg, vim.log.ERROR)
      return
    end

    -- editing the given filepath updates the current buffer
    vim.cmd("e " .. opts.filepath)
  end

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.slides = parsing.parse_lines(lines, state.config)
  state.current_slide = 1
  state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  state.floats = windows.create_floating_windows()

  set_presentation_keymaps()

  local original_vim_options = {
    cmdheight = vim.o.cmdheight,
    conceallevel = vim.o.conceallevel,
    -- TODO: need to restore the state of hlsearch, not just the option
    hlsearch = vim.o.hlsearch,
    linebreak = vim.o.linebreak,
    wrap = vim.o.wrap,
  }

  -- Set the options we want during presentation
  for name, value in pairs(state.config.presentation_vim_options) do
    vim.opt[name] = value
  end

  local present_augroup = vim.api.nvim_create_augroup("PresentNvim", {})

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.floats.body.buf,
    group = present_augroup,
    callback = function()
      -- reset the option values when we are done with the presentation
      for name, value in pairs(original_vim_options) do
        vim.opt[name] = value
      end

      utils.foreach(state.floats, function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)

      state.active = false
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = present_augroup,
    callback = function()
      if not vim.api.nvim_win_is_valid(state.floats.body.win) or state.floats.body.win == nil then
        return
      end

      windows.update_floating_windows(state.floats)

      -- Re-calculates current slide contents
      set_slide_content(state.current_slide)
    end,
  })

  set_slide_content(state.current_slide)

  state.active = true
end

M.end_presentation = function()
  vim.api.nvim_win_close(state.floats.body.win, true)

  state.active = false
end

---@param config present.Config | nil
M.setup = function(config)
  config = config or {}

  state.config = vim.tbl_deep_extend("force", state.config, config)
end

M.create_system_executor = execution.create_system_executor

-- NOTE: expose for testing
M._state = state

return M
