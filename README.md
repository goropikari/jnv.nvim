# jnv.nvim

This is a Neovim plugin that allows you to run the [`jnv`][1] command on selected text or the current buffer. The [`jnv`][1] command is used to format JSON data in a more readable and human-friendly way.

To use this plugin, you need to have the [`jnv`][1] command installed on your system.


## Installation

For [`lazy.nvim`][2]

```lua
{
  "goropikari/jnv.nvim",
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    -- default configuration
    path = 'jnv', -- path to jnv
    args = {}, -- the arguments passed to the jnv
    window = {
      layout = 'vertical', -- 'vertical', 'horizontal', 'float', 'replace'
      width = 0.5, -- fractional width of parent
      height = 0.5, -- fractional height of parent
      -- Options below only apply to floating windows
      relative = 'editor', -- 'editor', 'win', 'cursor', 'mouse'
      border = 'single', -- 'none', single', 'double', 'rounded', 'solid', 'shadow'
      row = nil, -- row position of the window, default is centered
      col = nil, -- column position of the window, default is centered
      title = 'jnv', -- title of window
    },
  }
}
```

```lua
require("jnv").setup({ args = { "--indent", 4 } })
```

This will set the `--indent` option to `4` for all JSON files that are opened in Neovim. You can adjust the options as needed.

## Usage

* Supports both visual selection and current buffer.

For current buffer
1. Open a json file
1. Launch [`jnv`][1] via `:lua require('jnv').jnv_current_buffer()`

For selection
1. Define keymap as mentioned below
1. Select json part
1. Type defined keymap

jnv.nvim does not configure any mappings by default to avoid conflicts with user defined keymaps.
Some example mappings you could configure:

```lua
vim.keymap.set('n', '<leader>jn', jnv_current_buffer, { noremap = true, silent = true })
vim.keymap.set('v', '<leader>jn', jnv_selection, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>jt', function()
  require('telescope').extensions.jnv.jnv()
  -- or vim.cmd([[:Telescope jnv]])
end, { noremap = true, silent = true })
vim.api.nvim_create_user_command('JnvSelection', function(opts)
  jnv_selection(opts)
end, { range = 0 })
vim.api.nvim_create_user_command('JnvCurrentBuffer', function()
  jnv_current_buffer()
end, {})
```

[1]: https://github.com/ynqa/jnv
[2]: https://github.com/folke/lazy.nvim
