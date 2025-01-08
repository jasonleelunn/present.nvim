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

Inspired by and adapted from @tjdevries ["Neovim Plugin from Scratch" YouTube series](https://www.youtube.com/watch?v=VGid4aN25iI&list=PLep05UYkc6wTyBe7kPjQFWVXTlhKeQejM&index=18)

See also [tjdevries/present.nvim](https://github.com/tjdevries/present.nvim)
