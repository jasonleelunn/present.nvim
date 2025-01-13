local M = {}

---@param lines string[]: The lines in the buffer
---@param opts present.Config?
---@return present.Slide[]: The slides of the file
M.parse_lines = function(lines, opts)
  opts = opts or {}

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

  local separator_matchers = opts.separators or {}

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

      if opts.hide_separator_in_title then
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

return M
