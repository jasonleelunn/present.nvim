local execution = require("present.execution")

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
---@field separators string[]?: The list of patterns to use to find slide boundaries/titles

local state = {
  config = {
    hide_separator_in_title = true,
    separators = { "^# " },
    keymaps = {
      execute_code_blocks = "X",
      previous_slide = "p",
      next_slide = "n",
      quit_presentation = "q",
    },
  },
  slides = {},
  current_slide = 1,
  floats = {},
}

local function create_floating_window(config, enter)
  if enter == nil then
    enter = false
  end

  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  local win = vim.api.nvim_open_win(buf, enter, config)

  return { buf = buf, win = win }
end

local function create_window_configurations()
  local full_width = vim.o.columns
  local full_height = vim.o.lines

  local header_height = 2 + 1 -- border + single line
  local footer_height = 1 -- no border, single line

  -- TODO: make configurable
  local horizontal_body_padding = 8

  local body_height = full_height - header_height - footer_height - 2 -- account for the body border top and bottom
  local body_width = full_width - horizontal_body_padding * 2 -- pad left and right of body text

  return {
    background = {
      relative = "editor",
      width = full_width,
      height = full_height,
      col = 0,
      row = 0,
      zindex = 1,
      style = "minimal",
    },
    header = {
      relative = "editor",
      width = full_width,
      height = 1,
      col = 0,
      row = 0,
      zindex = 3,
      style = "minimal",
      border = "rounded",
    },
    body = {
      relative = "editor",
      width = body_width,
      height = body_height,
      col = horizontal_body_padding,
      row = header_height,
      zindex = 2,
      style = "minimal",
      -- invisible horizontal borders at the top and bottom only
      border = { "", " ", "", "", "", " ", "", "" },
    },
    footer = {
      relative = "editor",
      width = full_width,
      height = 1,
      col = 0,
      row = full_height - 1,
      zindex = 3,
      style = "minimal",
    },
  }
end

local function foreach_float(cb)
  for name, float in pairs(state.floats) do
    cb(name, float)
  end
end

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

---@param lines string[]: The lines in the buffer
---@return present.Slide[]: The slides of the file
local parse_lines = function(lines)
  local slides = {}

  local current_slide = {
    title = "",
    body = {},
    blocks = {},
  }

  local current_block = {
    language = nil,
    body = "",
  }

  ---@type string[]: default value has already been applied in `setup`
  local separator_matchers = state.config.separators

  local inside_block = false

  for _, line in ipairs(lines) do
    -- TODO: test for robustness, don't want to pick up bash # comments for example
    if vim.startswith(line, "```") then
      inside_block = not inside_block

      if inside_block then
        -- get everything after the three backticks
        current_block.language = line:sub(4)
      else
        current_block.body = vim.trim(current_block.body)
        table.insert(current_slide.blocks, current_block)

        current_block = {
          language = nil,
          body = "",
        }
      end
    else
      if inside_block then
        current_block.body = current_block.body .. line .. "\n"
      end
    end

    local separator_start, separator_end = nil, nil

    for _, matcher in ipairs(separator_matchers) do
      separator_start, separator_end = line:find(matcher)

      if separator_start ~= nil then
        break
      end
    end

    if separator_start and separator_end and not inside_block then
      if #current_slide.title > 0 then
        table.insert(slides, current_slide)
      end

      local title = line

      if state.config.hide_separator_in_title then
        -- remove the separator from the displayed title
        -- TODO: test removal of separators not at start of string
        title = vim.trim(string.format("%s%s", line:sub(0, separator_start - 1), line:sub(separator_end)))
      end

      current_slide = {
        title = title,
        body = {},
        blocks = {},
      }
    else
      table.insert(current_slide.body, line)
    end
  end

  table.insert(slides, current_slide)

  return slides
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.slides = parse_lines(lines)
  state.current_slide = 1
  -- TODO: allow specifying a filepath
  state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  local windows = create_window_configurations()
  state.floats.background = create_floating_window(windows.background)
  state.floats.header = create_floating_window(windows.header)
  state.floats.footer = create_floating_window(windows.footer)
  state.floats.body = create_floating_window(windows.body, true)

  foreach_float(function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  local keymaps = state.config.keymaps

  set_presentation_keymap("n", keymaps.previous_slide, function()
    state.current_slide = math.max(state.current_slide - 1, 1)
    set_slide_content(state.current_slide)
  end)

  set_presentation_keymap("n", keymaps.next_slide, function()
    state.current_slide = math.min(state.current_slide + 1, #state.slides)
    set_slide_content(state.current_slide)
  end)

  set_presentation_keymap("n", keymaps.quit_presentation, function()
    vim.api.nvim_win_close(state.floats.body.win, true)
  end)

  set_presentation_keymap("n", keymaps.execute_code_blocks, function()
    execution.execute_slide_blocks(state)
  end)

  local vim_options = {
    original = {
      cmdheight = vim.o.cmdheight,
      conceallevel = vim.o.conceallevel,
      -- TODO: need to restore the state of hlsearch, not just the option
      hlsearch = vim.o.hlsearch,
      linebreak = vim.o.linebreak,
      wrap = vim.o.wrap,
    },
    present = {
      cmdheight = 0,
      -- TODO: make all these configurable
      conceallevel = 2,
      hlsearch = false,
      linebreak = true,
      wrap = true,
    },
  }

  -- Set the options we want during presentation
  for name, value in pairs(vim_options.present) do
    vim.opt[name] = value
  end

  local present_augroup = vim.api.nvim_create_augroup("PresentNvim", {})

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.floats.body.buf,
    group = present_augroup,
    callback = function()
      -- reset the option values when we are done with the presentation
      for name, value in pairs(vim_options.original) do
        vim.opt[name] = value
      end

      foreach_float(function(_, float)
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

      local updated = create_window_configurations()

      foreach_float(function(name, float)
        vim.api.nvim_win_set_config(float.win, updated[name])
      end)

      -- Re-calculates current slide contents
      set_slide_content(state.current_slide)
    end,
  })

  set_slide_content(state.current_slide)
end

---@param config present.Config | nil
M.setup = function(config)
  config = config or {}
  -- opts.executors = opts.executors or {}

  state.config = vim.tbl_extend("force", state.config, config)
end

-- NOTE: expose for testing
M._parse_lines = parse_lines

return M
