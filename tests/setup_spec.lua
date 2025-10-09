---@diagnostic disable: undefined-global

local state = require("present")._state
local setup = require("present").setup
local start_presentation = require("present").start_presentation
local end_presentation = require("present").end_presentation

local eq = assert.are.same

describe("present.setup", function()
  it("should use the default config with no arguments", function()
    local expected_default_options = {
      cmdheight = 0,
      conceallevel = 0,
      hlsearch = false,
      linebreak = true,
      wrap = true,
    }

    local original_options = {}
    -- store current vim options before present starts
    for option, _ in pairs(expected_default_options) do
      original_options[option] = vim.o[option]
    end

    setup()
    start_presentation()

    for option, value in pairs(expected_default_options) do
      eq(vim.o[option], value)
    end

    end_presentation()

    for option, value in pairs(original_options) do
      eq(vim.o[option], value)
    end
  end)

  it("should use the user supplied config", function()
    local user_supplied_options = {
      conceallevel = 2,
      linebreak = false,
    }

    local original_options = {}
    -- store current vim options before presentation starts
    for option, _ in pairs(user_supplied_options) do
      original_options[option] = vim.o[option]
    end

    setup({
      presentation_vim_options = user_supplied_options,
    })

    -- user supplied options should be merged with the defaults
    eq(state.config.presentation_vim_options, {
      cmdheight = 0,
      conceallevel = 2,
      hlsearch = false,
      linebreak = false,
      wrap = true,
    })

    start_presentation()

    for option, value in pairs(user_supplied_options) do
      eq(vim.o[option], value)
    end

    end_presentation()

    for option, value in pairs(original_options) do
      eq(vim.o[option], value)
    end
  end)

  it("should allow overriding the default keymaps", function()
    local user_config = {
      keymaps = {
        next_slide = "l",
      },
    }

    setup(user_config)

    start_presentation({ filepath = "tests/test_slides.md" })

    -- should advance to the next slide
    vim.api.nvim_feedkeys("l", "x", true)

    eq(state.current_slide, 2)

    end_presentation()
  end)

  it("should allow partial overriding of the footer config table", function()
    local left_text = "foo bar baz"

    local user_config = {
      footer = {
        left_text = left_text,
      },
    }

    setup(user_config)

    start_presentation({ filepath = "tests/test_slides.md" })

    eq(state.config.footer, {
      left_text = left_text,
      right_text = nil,
    })

    end_presentation()
  end)
end)
