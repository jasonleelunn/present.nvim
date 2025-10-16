---@diagnostic disable: undefined-global

local setup = require("present").setup
local start_presentation = require("present").start_presentation
local end_presentation = require("present").end_presentation

local eq = assert.are.same

describe("present.windows", function()
  it("should set the filetype to markdown for all of the presentation buffers", function()
    setup()
    start_presentation({ filepath = "tests/test_slides.md" })

    local buffer_ids = vim.api.nvim_list_bufs()

    -- original file buffer + header + footer + background + body + intro
    eq(#buffer_ids, 6)

    for _, buffer_id in ipairs(buffer_ids) do
      eq(vim.bo[buffer_id].filetype, "markdown")
    end

    end_presentation()
  end)

  it("should disable spell checking in the presentation window", function()
    vim.cmd("edit tests/test_slides.md")

    -- enable spell checking on the window before starting the presentation
    vim.o.spell = true

    setup()
    start_presentation({ filepath = "tests/test_slides.md" })

    eq(vim.o.spell, false)

    end_presentation()
  end)
end)
