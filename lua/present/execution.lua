local M = {}

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
    local output = vim.split(compile_result.stderr, "\n")
    return output
  end

  local runtime_result = vim.system({ outputfile }, { text = true }):wait()

  if #runtime_result.stderr > 0 then
    return vim.split(runtime_result.stderr, "\n")
  end

  return vim.split(runtime_result.stdout, "\n")
end

---@param program string
---@return present.Executor
M.create_system_executor = function(program)
  ---@param block present.Block
  return function(block)
    local tempfile = vim.fn.tempname()
    vim.fn.writefile(vim.split(block.body, "\n"), tempfile)

    local result = vim.system({ program, tempfile }, { text = true }):wait()

    if #result.stderr > 0 then
      return vim.split(result.stderr, "\n")
    end

    return vim.split(result.stdout, "\n")
  end
end

---@param block present.Block
---@param executor present.Executor
M.execute_slide_block = function(block, executor)
  if not block then
    print("No code blocks found on this slide")
    return
  end

  if not executor then
    print("No valid executor configured for this language")
    return
  end

  local execution_result = executor(block)

  local output = { "# Code", "", "```" .. block.language }
  vim.list_extend(output, vim.split(block.body, "\n"))
  table.insert(output, "```")

  table.insert(output, "")
  table.insert(output, "# Output")
  table.insert(output, "")
  vim.list_extend(output, execution_result)

  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    noautocmd = true,
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
  })

  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
end

return M
