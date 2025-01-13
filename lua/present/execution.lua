local M = {}

--- Default executor for Go code
---@param block present.Block
M.execute_go_code = function(block)
  local tempfile = vim.fn.tempname() .. ".go"
  local outputfile = tempfile:sub(1, -4)

  vim.fn.writefile(vim.split(block.body, "\n"), tempfile)

  local compile_result = vim.system({ "go", "build", "-o", outputfile, tempfile }, { text = true }):wait()

  if compile_result.code ~= 0 then
    return vim.split(compile_result.stderr, "\n")
  end

  local runtime_result = vim.system({ outputfile }, { text = true }):wait()

  if #runtime_result.stderr > 0 then
    return vim.split(runtime_result.stderr, "\n")
  end

  return vim.split(runtime_result.stdout, "\n")
end

--- Default executor for Lua code
---@param block present.Block
M.execute_lua_code = function(block)
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
      table.insert(output, "Error: Failed to execute Lua code block")
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
M.execute_rust_code = function(block)
  local tempfile = vim.fn.tempname() .. ".rs"
  local outputfile = tempfile:sub(1, -4)

  vim.fn.writefile(vim.split(block.body, "\n"), tempfile)

  local compile_result = vim.system({ "rustc", tempfile, "-o", outputfile }, { text = true }):wait()

  if compile_result.code ~= 0 then
    return vim.split(compile_result.stderr, "\n")
  end

  local runtime_result = vim.system({ outputfile }, { text = true }):wait()

  if #runtime_result.stderr > 0 then
    return vim.split(runtime_result.stderr, "\n")
  end

  return vim.split(runtime_result.stdout, "\n")
end

---@param command string
---@return present.Executor
M.create_system_executor = function(command)
  ---@param block present.Block
  return function(block)
    local tempfile = vim.fn.tempname()
    vim.fn.writefile(vim.split(block.body, "\n"), tempfile)

    local result = vim.system({ command, tempfile }, { text = true }):wait()

    if #result.stderr > 0 then
      return vim.split(result.stderr, "\n")
    end

    return vim.split(result.stdout, "\n")
  end
end

return M
