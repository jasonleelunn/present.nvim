---@class present.Slide
---@field title string The title of the slide
---@field body string[] The body of slide
---@field blocks present.Block[] A codeblock inside of a slide

---@class present.Block
---@field language string The language of the codeblock
---@field body string The body of the codeblock

---@alias present.Executor fun(block: present.Block): string[]
---@alias present.ExecutionResult { block: present.Block, output: string[] }

---@class present.Config
---@field executors { [string]: present.Executor }? Table of language execution functions
---@field footer present.FooterOptions? Options to configure the footer content
---@field hide_separator_in_title boolean? Whether to remove the separator char(s) from the slide header
---@field presentation_vim_options table? Table of vim options to set during presentation mode, see :help option-list
---@field separators string[]? The list of patterns to use to find slide boundaries/titles

---@class present.StartOptions
---@field bufnr number? Buffer number containing slides to present. Defaults to the current buffer `0`
---@field filepath string? The path to file containing slides to present. Takes precedence over `bufnr`

---@class present.FooterOptions
---@field left_text string? The text to display in the left footer area. Defaults to the slide number count and the filename
---@field right_text string? The text to display in the right footer area. Defaults to the current date in the "YYYY-MM-DD" format
