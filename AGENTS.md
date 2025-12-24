# AGENTS.md

## Overview
LazyVim-based Neovim configuration. No build/test commands—use `:Lazy` for plugin management.

## Formatting & Linting
- **StyLua** for Lua: 2 spaces indent, 120 char line width (see `stylua.toml`)
- Run: `stylua lua/` or use Neovim's `:ConformFormat`
- Use `-- stylua: ignore` for lines that shouldn't be formatted

## Code Style
- **Plugin files**: Return a table `{ "author/plugin", opts = {...} }`
- **File naming**: kebab-case for plugins (`lsp-config.lua`), lowercase for config (`options.lua`)
- **Imports**: Use `require("module")` syntax
- **Type annotations**: Use LuaCATS (`---@type`, `---@param`, `---@module`)
- **Options**: Simple configs use `opts = {}`, complex use `opts = function(_, opts) end`
- **Global**: `LazyVim` object available for utilities

## Structure
```
lua/config/   -- autocmds, keymaps, options, lazy bootstrap
lua/plugins/  -- one file per plugin or feature
```

## Key Settings
Leader: `;` | Colorscheme: `github_dark_dimmed` | Completion: `blink.cmp`
