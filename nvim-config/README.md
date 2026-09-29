# nvim config

flowchart TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]

## Layout

```
nvim/
├── init.lua                 entrypoint — just requires everything below, in order
├── lazy-lock.json           generated after first launch; commit this to dotfiles
└── lua/
    ├── lazy-bootstrap.lua    clones/installs lazy.nvim itself, nothing else
    ├── lazy-plugins.lua      calls lazy.setup(), auto-imports lua/plugins/*
    ├── config/
    │   ├── options.lua       vim.opt settings, no plugin deps
    │   ├── keymaps.lua       global keymaps, no plugin deps
    │   └── autocmds.lua      autocommands, no plugin deps
    └── plugins/
        ├── colorscheme.lua
        ├── statusline.lua
        ├── telescope.lua
        ├── treesitter.lua
        ├── lsp.lua
        ├── completion.lua
        └── gitsigns.lua
```

## Load order (from init.lua)

1. `config.options` / `config.keymaps` / `config.autocmds` — plain settings,
   no plugins involved yet. `mapleader` is set here, before anything else
   loads, which matters for plugin keymaps registered later.
2. `lazy-bootstrap` — installs lazy.nvim to the data dir if missing, adds
   it to `rtp`. Knows nothing about which plugins you use.
3. `lazy-plugins` — calls `require("lazy").setup(...)` with
   `spec = { { import = "plugins" } }`, which walks `lua/plugins/` and
   treats every file's return value as a plugin spec.

## Adding / removing a plugin

- **Add**: create a new file in `lua/plugins/`, e.g. `lua/plugins/foo.lua`,
  that returns a lazy.nvim spec table (or list of tables). No need to
  register it anywhere else — `lazy-plugins.lua`'s `{ import = "plugins" }`
  picks it up automatically.
- **Remove**: delete the file, then run `:Lazy clean` to remove the
  plugin from disk.
- Plugin-specific keymaps go inside that plugin's own spec file (in a
  `keys = {}` table where possible, so they're lazy-loaded correctly),
  never in `config/keymaps.lua`.

## First launch on a new machine

1. Symlink or copy this whole `nvim/` folder to `~/.config/nvim`
   (this is what makes it dotfiles-portable — see suggestion below).
2. Open `nvim`. `lazy-bootstrap.lua` clones lazy.nvim automatically,
   then `lazy-plugins.lua` installs everything declared in `lua/plugins/`.
3. If a `lazy-lock.json` was committed in your dotfiles, plugins install
   at those exact pinned commits — reproducible across machines.
4. Run `:Mason` if you need to check/install LSP servers beyond `lua_ls`
   (add more to the `ensure_installed` list in `lua/plugins/lsp.lua`).

## Dotfiles integration

Recommended: manage this repo with [GNU Stow](https://www.gnu.org/software/stow/)
or a symlink script, e.g.:

```
dotfiles/
└── nvim/
    └── .config/
        └── nvim/        <- this whole folder
```

```sh
cd ~/dotfiles
stow nvim   # symlinks nvim/.config/nvim -> ~/.config/nvim
```

Commit `lazy-lock.json` after your first successful install so the new
PC gets identical plugin versions rather than "whatever's latest."
