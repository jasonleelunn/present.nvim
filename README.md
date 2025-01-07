# `present.nvim`

Hey, this is a plugin for presenting markdown files!

# Features: Neovim Lua Execution

Can execute code in lua blocks, when you have them in a slide

```lua
print("Hello world", 37, true)
```

# Usage

```lua
require("present").start_presentation {}
```

Use `n`, and `p` to navigate markdown slides.

Or use `:PresentStart` Command

# Acknowledgements

teej_dv
