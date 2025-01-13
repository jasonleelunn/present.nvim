local utils = require("present.utils")

local M = {}

local function create_window_configurations()
  local full_width = vim.o.columns
  local full_height = vim.o.lines

  local header_height = 2 + 1 -- border + single line
  local footer_height = 1 -- no border, single line

  -- TODO: make configurable
  local horizontal_body_padding = 8

  local body_height = full_height - header_height - footer_height - 2 -- account for the body border top and bottom
  local body_width = full_width - horizontal_body_padding * 2 -- pad left and right of body text

  -- TODO: make configurable
  local execution_height = math.floor(full_height * 0.5)
  local execution_width = math.floor(full_width * 0.6)

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
    execution = {
      relative = "editor",
      width = execution_width,
      height = execution_height,
      col = math.floor((full_width - execution_width) / 2),
      row = math.floor((full_height - execution_height) / 2),
      zindex = 4,
      style = "minimal",
      border = "rounded",
      noautocmd = true,
    },
  }
end

local function create_floating_window(config, enter)
  if enter == nil then
    enter = false
  end

  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  local win = vim.api.nvim_open_win(buf, enter, config)

  return { buf = buf, win = win }
end

M.create_floating_windows = function()
  local floats = {}

  local windows = create_window_configurations()

  floats.background = create_floating_window(windows.background)
  floats.header = create_floating_window(windows.header)
  floats.footer = create_floating_window(windows.footer)
  floats.body = create_floating_window(windows.body, true)

  utils.foreach(floats, function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  return floats
end

M.update_floating_windows = function(floats)
  local updated = create_window_configurations()

  utils.foreach(floats, function(name, float)
    vim.api.nvim_win_set_config(float.win, updated[name])
  end)
end

M.create_execution_result_window = function(text)
  local windows = create_window_configurations()
  local float = create_floating_window(windows.execution, true)

  vim.bo[float.buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, text)
end

return M
