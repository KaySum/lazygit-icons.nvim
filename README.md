# lazygit-icons.nvim

Makes Neovim show the same file icons and colors as
[lazygit](https://github.com/jesseduffield/lazygit), by overriding
[mini.icons](https://github.com/nvim-mini/mini.icons) with lazygit's icon table.

Anything that gets its icons from mini.icons (or from its `nvim-web-devicons`
mock) picks them up.

## Install

lazy.nvim:

```lua
{ 'KaySum/lazygit-icons.nvim', dependencies = { 'nvim-mini/mini.icons' }, opts = {} }
```

Anything else: call `require('lazygit-icons').setup()` after mini.icons' own
`setup()`. Its config is extended, not replaced.

## Overriding only some icons

By default every icon lazygit knows is overridden. Pass `only` to override just
the listed file names and extensions and leave everything else to mini.icons:

```lua
opts = { only = { 'Makefile', '.gitignore', '*.lua', '*.tsx' } }
```

`*.ext` is an extension; anything else is an exact file name. Entries lazygit
has no icon for are ignored.

To take only lazygit's icon or only its color for an entry, write it as a key:

```lua
opts = {
  only = {
    'Makefile',          -- icon and color
    ['*.lua'] = 'icon',  -- lazygit's icon, mini.icons' color
    ['*.tsx'] = 'color', -- lazygit's color, mini.icons' icon
  },
}
```

## Leaving some icons alone

`except` is the reverse: everything is overridden apart from the listed file
names and extensions, which keep the icon and color mini.icons gives them.

```lua
opts = { except = { 'Makefile', 'init.lua', '*.tsx' } }
```

A keyed entry leaves just that part alone:

```lua
opts = {
  except = {
    'Makefile',          -- mini.icons' icon and color
    ['*.lua'] = 'icon',  -- mini.icons' icon, lazygit's color
    ['*.tsx'] = 'color', -- mini.icons' color, lazygit's icon
  },
}
```

It can be combined with `only`, and wins where the two overlap.

## What matches lazygit

A file gets the icon lazygit would give it: by exact file name first, then by
the lowercased text after the last dot. That includes two things lazygit does
that may look surprising:

- `thing.test.tsx` gets the plain `.tsx` icon. lazygit's table has entries like
  `.test.tsx`, but its lookup never reaches them.
- File names mini.icons treats specially (`init.lua`, `README.md`, ...) get the
  icon for their extension, because lazygit has no special case for them.

## What does not

- Directories keep mini.icons' icons. lazygit uses one folder icon for all.
- Files lazygit has no icon for keep mini.icons' filetype-based icon. lazygit
  shows a generic file.
- Icons looked up by filetype rather than file name are untouched.
- lazygit's own `gui.customIcons` and `gui.nerdFontsVersion: "2"` settings are
  not read.

## Updating the icons

The table in `lua/lazygit-icons/icons.lua` is generated from lazygit's source.
After a lazygit release changes its icons, regenerate it:

```sh
nvim -l scripts/generate.lua          # the installed lazygit's version
nvim -l scripts/generate.lua 0.66.0   # a specific version
```

It currently matches lazygit v0.66.0.
