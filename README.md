# `present.nvim`

A Neovim plugin for presenting markdown files as slideshows.

# Usage

Start a presentation from the current buffer by calling `start_presentation` with no arguments, or optionally pass a table with a `filepath` field to present a specific file;

```lua
require("present").start_presentation({
    filepath = "/path/to/file.md" -- optional argument
})
```

or just run the `:PresentStart <filepath?>` command, optionally passing a file path to present

# Configuration

Calling the `setup` function is optional if you want to pass any configuation options, the following table shows all valid configuration options with their default values;

```lua
require("present").setup({
    -- whether the chosen separator character(s) should be removed from the slide header
    hide_separator_in_title = true,
    -- a list of lua matching patterns to use as slide boundaries
    -- lines matching one of these separators will become slide titles in the header
    separators = { "^# " },
    -- the normal mode keymaps available while in presentation mode, see the `Keymaps` section below
    keymaps = {
      execute_code_blocks = "X",
      previous_slide = "p",
      next_slide = "n",
      first_slide = "f",
      last_slide = "e",
      end_presentation = "q",
    },
    -- vim options that will be modified when in presentation mode
    -- you can pass any valid vim options here to customise how presentation mode behaves
    -- see :help option-list to see all valid fields for this table
    presentation_vim_options = {
      cmdheight = 0,
      conceallevel = 0,
      hlsearch = false,
      linebreak = true,
      wrap = true,
    },
    -- the default code executors available, see the `Live Code Block Execution` section below
    executors = {
      go = execution.execute_go_code,
      javascript = execution.create_system_executor("node"),
      lua = execution.execute_lua_code,
      python = execution.create_system_executor("python"),
      rust = execution.execute_rust_code,
    },
})
```

# Live Code Block Execution

You can execute code inside markdown code blocks on a slide, e.g.

```lua
print("Hello world!")
```

and the result will be displayed in a floating window

- Execution functions are provided for `lua`, `go`, `rust`, `python`, and `javascript` by default
- You can add your own to the `executors` table in the `setup` config table
- The default executors may not be compatible with your system and you may need to write a custom executor. See `lua/present/execution.lua` for example implementations
- For interpreted languages, you can use the `create_system_executor` utility function provided by `present.nvim` to easily create a new executor;

```lua
local present = require("present")

present.setup({
    executors = {
        ruby = present.create_system_executor("ruby")
    }
})
```

# Keymaps

These keymaps are active in normal mode when presenting a file. You can customise them using the `keymaps` table in the config table passed to `setup` (see [Configuration](#configuration) above)

| key | description                          |
| --- | ------------------------------------ |
| `p` | move to the previous slide           |
| `n` | move to the next slide               |
| `f` | move to the first slide              |
| `e` | move to the last slide               |
| `q` | quit the presentation                |
| `X` | execute the code blocks on the slide |

# Acknowledgements

Inspired by and adapted from @tjdevries ["Neovim Plugin from Scratch" YouTube series](https://www.youtube.com/watch?v=VGid4aN25iI&list=PLep05UYkc6wTyBe7kPjQFWVXTlhKeQejM&index=18)

See also [tjdevries/present.nvim](https://github.com/tjdevries/present.nvim)
