---@diagnostic disable: undefined-global

local state = require("present")._state
local setup = require("present").setup
local parse = require("present.parsing").parse_lines

local eq = assert.are.same

describe("present.parsing", function()
  describe("parse_lines", function()
    before_each(function()
      setup({})
    end)

    it("should parse an empty file", function()
      local expected = {
        {
          title = "",
          body = {},
          blocks = {},
        },
      }

      local actual = parse({}, state.config)

      eq(expected, actual)
    end)

    it("should parse a file with one slide", function()
      local expected = {
        {
          title = "Title",
          body = { "Body text" },
          blocks = {},
        },
      }

      local actual = parse({
        "# Title",
        "Body text",
      }, state.config)

      eq(expected, actual)
    end)

    it("should parse a file with multiple slides", function()
      local expected = {
        {
          title = "Slide 1",
          body = { "Body text 1" },
          blocks = {},
        },
        {
          title = "Slide 2",
          body = { "Body text 2" },
          blocks = {},
        },
        {
          title = "Slide 3",
          body = { "Body text 3" },
          blocks = {},
        },
      }

      local actual = parse({
        "# Slide 1",
        "Body text 1",
        "# Slide 2",
        "Body text 2",
        "# Slide 3",
        "Body text 3",
      }, state.config)

      eq(expected, actual)
    end)

    it("should parse a file with one slide containing one code block", function()
      local slides = parse({
        "# Title",
        "Body text",
        "```lua",
        "print('hi')",
        "```",
      }, state.config)

      eq(#slides, 1)

      local slide = slides[1]

      eq("Title", slide.title)

      eq({
        "Body text",
        "```lua",
        "print('hi')",
        "```",
      }, slide.body)

      eq({
        language = "lua",
        body = "print('hi')",
      }, slide.blocks[1])
    end)

    it("should parse a file with one slide containing multiple code blocks", function()
      local slides = parse({
        "# Title",
        "Body text",
        "```lua",
        "print('hi')",
        "```",
        "More text",
        "```javascript",
        "console.log('hi')",
        "```",
      }, state.config)

      eq(#slides, 1)

      local slide = slides[1]

      eq("Title", slide.title)

      eq({
        "Body text",
        "```lua",
        "print('hi')",
        "```",
        "More text",
        "```javascript",
        "console.log('hi')",
        "```",
      }, slide.body)

      eq({
        language = "lua",
        body = "print('hi')",
      }, slide.blocks[1])

      eq({
        language = "javascript",
        body = "console.log('hi')",
      }, slide.blocks[2])
    end)
  end)
end)
