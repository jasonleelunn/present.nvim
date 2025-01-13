---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of slide
---@field blocks present.Block[]: A codeblock inside of a slide

---@class present.Block
---@field language string: The language of the codeblock
---@field body string: The body of the codeblock

---@alias present.Executor fun(block: present.Block): string[]

---@class present.Config
---@field executors { [string]: present.Executor }?: Table of language execution functions
---@field hide_separator_in_title boolean?: TODO: add description
---@field presentation_vim_options table?: Table of vim options to set during presentation mode, see :help option-list
---@field separators string[]?: The list of patterns to use to find slide boundaries/titles

---@class present.StartOptions
---@field bufnr number?: Buffer number containing slides to present. Defaults to the current buffer `0`
---@field filepath string?: The path to file containing slides to present. Takes precedence over `buffer_number`
