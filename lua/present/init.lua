local execution = require("present.execution")
local parsing = require("present.parsing")
local utils = require("present.utils")
local windows = require("present.windows")

local M = {}

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of slide
---@field blocks present.Block[]: A codeblock inside of a slide

---@class present.Block
---@field language string: The language of the codeblock
---@field body string: The body of the codeblock

---@class present.Config
---@field hide_separator_in_title boolean?: TODO: add description
---@field presentation_vim_options table?: Table of vim options to set during presentation mode, see :help option-list
---@field separators string[]?: The list of patterns to use to find slide boundaries/titles

---@class present.StartOptions
---@field bufnr number?: Buffer number containing slides to present. Defaults to the current buffer `0`
---@field filepath string?: The path to file containing slides to present. Takes precedence over `buffer_number`

local state = {
  config = {
    hide_separator_in_title = true,
    separators = { "^# " },
    keymaps = {
      execute_code_blocks = "X",
      previous_slide = "p",
      next_slide = "n",
      end_presentation = "q",
    },
    presentation_vim_options = {
      cmdheight = 0,
      conceallevel = 0,
      hlsearch = false,
      linebreak = true,
      wrap = true,
    },
  },
  slides = {},
  current_slide = 1,
  floats = {},
}

local function set_presentation_keymap(mode, key, callback)
  vim.keymap.set(mode, key, callback, {
    buffer = state.floats.body.buf,
  })
end

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

---@param opts present.StartOptions | nil
M.start_presentation = function(opts)
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

  local keymaps = state.config.keymaps

  set_presentation_keymap("n", keymaps.previous_slide, function()
    state.current_slide = math.max(state.current_slide - 1, 1)
    set_slide_content(state.current_slide)
  end)

  set_presentation_keymap("n", keymaps.next_slide, function()
    state.current_slide = math.min(state.current_slide + 1, #state.slides)
    set_slide_content(state.current_slide)
  end)

  set_presentation_keymap("n", keymaps.end_presentation, function()
    M.end_presentation()
  end)

  set_presentation_keymap("n", keymaps.execute_code_blocks, function()
    execution.execute_slide_blocks(state)
  end)

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
end

M.end_presentation = function()
  vim.api.nvim_win_close(state.floats.body.win, true)
end

---@param config present.Config | nil
M.setup = function(config)
  config = config or {}
  -- opts.executors = opts.executors or {}

  state.config = vim.tbl_deep_extend("force", state.config, config)
end

-- NOTE: expose for testing
M._state = state

return M
