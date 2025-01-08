local M = {}

--- Default executor for lua code
---@param block present.Block
local execute_lua_code = function(block)
  -- Override the default print function, to capture all of the output
  -- Store the original print function
  local original_print = print

  local output = {}

  -- Redefine the print function
  print = function(...)
    local args = { ... }
    local message = table.concat(vim.tbl_map(tostring, args), "\t")
    table.insert(output, message)
  end

  -- Call the provided function
  local chunk = loadstring(block.body)
  pcall(function()
    if not chunk then
      table.insert(output, " <<<BROKEN CODE>>>")
    else
      chunk()
    end

    return output
  end)

  -- Restore the original print function
  print = original_print

  return output
end

--- Default executor for Rust code
---@param block present.Block
local execute_rust_code = function(block)
  local tempfile = vim.fn.tempname() .. ".rs"
  local outputfile = tempfile:sub(1, -4)
  vim.fn.writefile(vim.split(block.body, "\n"), tempfile)
  local result = vim.system({ "rustc", tempfile, "-o", outputfile }, { text = true }):wait()
  if result.code ~= 0 then
    local output = vim.split(result.stderr, "\n")
    return output
  end
  result = vim.system({ outputfile }, { text = true }):wait()
  return vim.split(result.stdout, "\n")
end

M.create_system_executor = function(program)
  return function(block)
    local tempfile = vim.fn.tempname()
    vim.fn.writefile(vim.split(block.body, "\n"), tempfile)
    local result = vim.system({ program, tempfile }, { text = true }):wait()
    return vim.split(result.stdout, "\n")
  end
end

M.execute_slide_blocks = function(state)
  local slide = state.parsed.slides[state.current_slide]
  -- TODO: Make a way for people to execute this for other languages
  local block = slide.blocks[1]
  if not block then
    print("No blocks on this page")
    return
  end

  local executor = options.executors[block.language]
  if not executor then
    print("No valid executor for this language")
    return
  end

  -- Table to capture print messages
  local output = { "# Code", "", "```" .. block.language }
  vim.list_extend(output, vim.split(block.body, "\n"))
  table.insert(output, "```")

  table.insert(output, "")
  table.insert(output, "# Output")
  table.insert(output, "")
  table.insert(output, "```")
  vim.list_extend(output, executor(block))
  table.insert(output, "```")

  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  local temp_width = math.floor(vim.o.columns * 0.8)
  local temp_height = math.floor(vim.o.lines * 0.8)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    noautocmd = true,
    width = temp_width,
    height = temp_height,
    row = math.floor((vim.o.lines - temp_height) / 2),
    col = math.floor((vim.o.columns - temp_width) / 2),
    border = "rounded",
  })

  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
end

-- local options = {
--   executors = {
--     lua = execute_lua_code,
--     javascript = M.create_system_executor("node"),
--     python = M.create_system_executor("python"),
--     rust = execute_rust_code,
--   },
-- }

return M
