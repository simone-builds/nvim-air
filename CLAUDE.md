# CLAUDE.md

Working notes for this repository: **airnvim**, a Neovim packaged with
**Nix** (flake) through BirdeeHub's `nix-wrapper-modules`, using the
**`lze`** / **`lzextras`** plugin loader.

## What this project is

Not a Neovim config to drop into `~/.config/nvim`: a **Nix flake** that
produces a self-contained package with plugins, language servers, linters
and CLI tools already on its `PATH`. The Lua config lives in this
repository (`settings.config_directory = ./.`) and is injected into the
wrapper.

- `flake.nix` — inputs (`nixpkgs`, `wrappers`, `flake-parts`,
  `plugins-lze`, `plugins-lzextras`) and outputs: `packages.default`,
  `wrappers.airnvim`, `nixosModules`, `homeModules`, `overlays`.
- `module.nix` — the Nix core: declares `options.settings` (feature flags),
  the `nvim-lib.pluginsFromPrefix` helper, and the `specs`, i.e. the plugin
  and package groups. Plugins, language servers and linters are added here.
- `init.lua` — bootstrap: configures `lze`, registers the custom handlers,
  loads `core.*` and `tools`, then the specs under `lua/plugins/`.

The wrapper is named `airnvim` but the binary stays **`nvim`**
(`binName = "nvim"`), with `nv` as its only alias.

The guiding constraint is lightness: the target profile is Nix, Bash and
Markdown daily, Lua occasionally. Anything heavier belongs behind a feature
flag that defaults to off.

### Load order (init.lua)

1. `vim.loader.enable()`.
2. Exposes `_G.nixInfo`, the bridge to the wrapper's information. Outside
   the wrapper it installs a stub returning the defaults, so the config
   still runs. `nixInfo.get_nix_plugin_path(name)` looks the plugin up in
   `plugins.lazy` / `plugins.start`.
3. Registers the `lze` handlers:
   - `auto_enable` — disables the spec when the plugin does not exist on
     the Nix side (accepts `true`, a string, or a list of names).
   - `for_cat` — enables based on `settings.cats.<name>`.
   - `nixInfo.lze.lsp` — the LSP handler from `lzextras`.
4. `require("core.options" | "core.keymaps" | "core.autocmds")` and
   `require("tools")`.
5. Collects specs from `lua/plugins/*.lua` with `mod_dir_to_spec`
   (excluding `dankcolors.lua`), flattens the lists, and calls
   `nixInfo.lze.load(specs)`.
6. `require("core.theme")` for transparency.

### The `nixInfo` API in Lua

`nixInfo(default, ...path)` reads a value from the Nix config with a
fallback:

```lua
nixInfo(75, "settings", "markdown", "line_length")
nixInfo("kitty", "settings", "render-backend")
nixInfo("", "settings", "obsidian", "vault")
nixInfo(false, "settings", "cats", "ai")       -- for_cat handler
```

## File layout

```text
init.lua              # lze bootstrap + spec loading
flake.nix             # inputs/outputs, wrappers.airnvim
module.nix            # feature flags, specs, plugins and packages
selene.toml           # lua lint; the "vim" std lives in vim.toml
vim.toml              # selene standard library for neovim

lua/core/
  options.lua         # vim.opt and vim.g. leader = '\'
  keymaps.lua         # global maps (H, L)
  autocmds.lua        # filetype, indentation
  mdwrap.lua          # markdown text wrapping, :MdWrap
  spell.lua           # opt-in spell checking, :SpellToggle
  rumdl.lua           # path to the generated rumdl rules file
  paths.lua           # resolves the real config directory
  theme.lua           # transparent background

lua/tools/
  init.lua            # loads the modules below
  open.lua            # vim.ui.open -> configurable programs
  lze.lua             # :LzeNix, :LzeStatus

lua/plugins/
  ui.lua              # lualine, alpha, devicons, fidget, todo, colorizer
  edit.lua            # sleuth, surround, autopairs, spectre, undotree,
                      # lazydev, actions-preview, plenary
  files.lua           # oil, telescope + extensions
  git.lua             # gitsigns, lazygit, diffview
  cmp.lua             # nvim-cmp, sources, luasnip
  lsp.lua             # nvim-lspconfig + one spec per server
  lint.lua            # nvim-lint
  format.lua          # conform
  treesitter.lua      # treesitter + textobjects
  markdown.lua        # render-markdown, image.nvim
  notes.lua           # obsidian.nvim
  ai.lua              # codecompanion
  dankcolors.lua      # theme, externally generated (do not rename)

queries/              # treesitter query overrides
spell/                # dictionaries (.spl only)
```

## Plugin spec conventions

Every file in `lua/plugins/` returns `{ ... }` with one `lze` spec or a
list of them. Recurring fields:

- `"plugin-name"` — first positional element, the Nix plugin name.
- `enabled`, `lazy` — standard booleans (note: `enabled`, not `enable`).
- `auto_enable` — enables only when the plugin exists on the Nix side.
  **Must be `false` when the setup lives in `after`**, otherwise the spec
  loads immediately.
- `for_cat = "<cat>"` — enables based on `settings.cats`, whose keys are
  the names of the top-level specs in `module.nix` (`ai`, `obsidian`,
  `general`, `lsp`, `lze`).
- `ft`, `cmd`, `event`, `keys` — lazy-loading triggers. **Every plugin
  needs one**: the project rule is that nothing loads unless used.
- `dep_of = { ... }` — declares the plugin as a dependency of others.
- `before` / `after(plugin)` — run before/after load; `after` is where
  `require("<plugin>").setup(plugin.opts)` goes.
- `opts` — a table **or a function** (a function must be evaluated, see
  `format.lua`).
- `version`, `branch` — pins (telescope uses `branch = '0.1.x'`).

Adding a plugin takes **two steps**: declare it in `module.nix`
(`specs.general.data` or a dedicated spec) **and** create its Lua spec in
`lua/plugins/`.

### LSP conventions (`lua/plugins/lsp.lua`)

LSP specs are not plugins: the first element is the **server name** and the
config lives in the `lsp = { ... }` field. The `lze.lsp` handler turns them
into `vim.lsp.config()` + `vim.lsp.enable()`.

```lua
{ "nixd", ft = { "nix" }, lsp = { root_markers = { "flake.nix" } } }
```

The `nvim-lspconfig` spec acts as the container: it injects the
`cmp_nvim_lsp` capabilities and, in `before`, configures `vim.diagnostic`
and the `LspAttach` autocmd with the buffer-local keymaps.

Always-on servers: `nixd`, `lua_ls`, `rumdl` (markdown). Optional servers
(`ruff`, `ts_ls`, `html`) use `enabled = vim.fn.executable("...") == 1`, so
they switch themselves on when the matching Nix flag puts the binary on the
`PATH`.

**Do not touch the `nixd` configuration**: it is an explicit project
constraint.

## Feature flags (module.nix → settings)

| Option                 | Default          | Effect                                         |
| ---------------------- | ---------------- | ---------------------------------------------- |
| `ai.enable`            | `false`          | CodeCompanion                                  |
| `ai.adapter`           | `copilot`        | Model backend                                  |
| `obsidian.enable`      | `true`           | obsidian.nvim                                  |
| `obsidian.vault`       | `""`             | Vault; empty keeps the plugin out of the build |
| `markdown.line_length` | `75`             | `textwidth` in `.md` and MD013                 |
| `spell.enable`         | `true`           | Whether `:SpellToggle` may turn spell on       |
| `spell.languages`      | `[ "it" "en" ]`  | Dictionaries                                   |
| `spell.filetypes`      | `[ "markdown" ]` | Where the toggle works                         |
| `nerd_font.enable`     | `true`           | Include file-type icons                        |
| `langs.python.enable`  | `false`          | `ruff`                                         |
| `langs.web.enable`     | `false`          | ts/js, html, css, json servers                 |
| `startup.cowsay`       | `true`           | `fortune \| cowsay` header                     |
| `render-backend`       | `kitty`          | Image backend                                  |
| `open.*`               | `""`             | External programs for `vim.ui.open`            |

`settings.cats` is **readOnly**, derived from
`mapAttrs (_: v: v.enable) config.specs`: every top-level spec becomes a
"cat" usable with `for_cat`. `specMods` adds the `runtimePkgs` field to all
specs, and the final `runtimePkgs` is the concatenation of all of them via
`config.specCollect`.

## Keybindings

`mapleader` and `maplocalleader` are both **`\`**.

### Core global maps

| Key         | Mode    | Source           | Action                |
| ----------- | ------- | ---------------- | --------------------- |
| `H` / `L`   | n, x, o | core/keymaps.lua | Start / end of line   |
| `-`         | n       | files.lua        | Oil in a float        |
| `<leader>z` | n       | core/spell.lua   | Toggle spell checking |

### Markdown emphasis (`.md` only, core/keymaps.lua)

Visual mode, three keys, each a plain `c<delim><C-r>"<delim><Esc>` mapping
registered from a `FileType markdown` autocmd:

| Key       | Wraps in     |
| --------- | ------------ |
| `<C-b>`   | `**bold**`   |
| `<C-i>`   | `*italic*`   |
| ``<C-`>`` | `` `code` `` |

Key encodings, checked against the bytes each one produces:

- `<C-b>` is byte `02`. Mapping it costs the page-back scroll in visual
  mode, which `<C-u>` still covers. Bold was on plain `B` at first, which
  is why it appeared broken: the other two are Ctrl chords, so `<C-b>` is
  what anyone actually reaches for.
- `<C-i>` is byte `09`, i.e. `<Tab>`. Tab therefore italicises too;
  harmless, since Tab does nothing in visual mode.
- `<C-[>` is byte `1B`, i.e. `<Esc>`. **Never map it** — it would take away
  leaving visual mode.
- ``<C-`>`` encodes as `80 FC 04 60`, which is not ASCII: it only arrives
  from terminals speaking the kitty keyboard protocol (kitty, WezTerm,
  Ghostty, foot). Elsewhere `nvim-surround`'s `S` is the fallback.

These mappings go through `c` and the unnamed register, which
`clipboard=unnamedplus` ties to the system clipboard: emphasising a word
replaces what you had copied. Swapping to a named register
(`"zc**<C-r>z**<Esc>`) avoids it if that ever becomes annoying.

### Visual / operator pending

| Key                      | Mode | Source         | Action                       |
| ------------------------ | ---- | -------------- | ---------------------------- |
| `<C-s>`                  | n, v | ai.lua         | CodeCompanion Actions        |
| `<leader>a`              | n, v | ai.lua         | AI chat                      |
| `ga`                     | v    | ai.lua         | Add to CodeCompanion         |
| `<leader>ca`             | n, v | edit.lua       | Code action with preview     |
| `<leader>sR`             | n, v | edit.lua       | Spectre on word or selection |
| `<leader>ol`             | v    | notes.lua      | Link the selection           |
| `<leader>onl`            | v    | notes.lua      | New note from the selection  |
| `S`                      | x    | nvim-surround  | Surround the selection       |
| `am` `im` `ac` `ic` `as` | x, o | treesitter.lua | Textobjects                  |

### Prefixes

- `<leader>s` — telescope (`sf`, `sg`, `sw`, `sb`, `sh`, `sk`, `sd`, `sr`,
  `s.`, `sn`) plus spectre in uppercase (`sR`, `sF`).
- `<leader>g` — git: `gg` LazyGit, `gd` Diffview open, `gq` close, `gh`
  history, `gc`/`gs`/`gb` telescope pickers.
- `<leader>o` — obsidian.
- `<leader>p` — `ps`/`pS` treesitter parameter swap.
- LSP buffer-local: `gd`, `gD`, `gr`, `gI`, `K`, `<C-k>`, `<leader>D`,
  `ds`, `ws`, `wa`, `wr`, `wl`, `e`, `rn`, `:Format`.

### Conflicts already resolved — do not reintroduce

| Key          | Assigned to        | What moved                     |
| ------------ | ------------------ | ------------------------------ |
| `<leader>a`  | CodeCompanion      | treesitter swap → `<leader>ps` |
| `<leader>sw` | telescope grep     | Spectre → `<leader>sR`         |
| `<leader>gc` | telescope commits  | Diffview close → `<leader>gq`  |
| `<leader>gb` | telescope branches | fugitive removed               |
| `<leader>ca` | actions-preview    | duplicate LSP nmap dropped     |

Buffer-local maps win over global ones; between two global maps the last
registered wins, so load order matters.

### Filetype-bound keymaps

Use a `FileType` autocmd with `vim.keymap.set(..., { buffer = args.buf })`,
so other filetypes are left alone.

## Markdown

- `render-markdown.nvim` colours the buffer; a `ColorScheme` autocmd gives
  bold and italic the `RenderMarkdownH1` colour.
- `rumdl` handles linting (as an LSP server), fixing and formatting on save
  via `conform`. **The rules are generated by `module.nix`**
  (`settings.markdown.rules_file`, a `writeText` in the store) rather than
  by a project `.rumdl.toml`: only this way do they apply outside this
  repository too.
- The LSP server **ignores overrides passed on the command line**
  (`--config`): the only channel that works is `settings.rumdl.configPath`.
  Verified by comparing diagnostics with and without. `disableRules` works,
  the `MD013` options do not.
- `MD013` trap: with `strict = true` the `headings`, `code-blocks` and
  `tables` exemptions **are ignored**. The generated file sets
  `strict = false`, otherwise long headings and code lines get flagged
  again.
- Disabled rules: `MD024` (headings with the same text), `MD025` (multiple
  level-1 headings), `MD041` (first line need not be a heading). The line
  limit applies to prose only.
- `lua/core/rumdl.lua` is the single place exposing the rules file path to
  `lsp.lua` and `format.lua`.
- Text wrapping is handled by `core/mdwrap.lua`, not prettier. The module
  does three things: sets `textwidth` (wrap as you type), removes the `t`
  flag from `formatoptions` inside code blocks (checked on line change, not
  on every keystroke), and reflows existing text with `gq` on save, plus on
  demand via `:MdWrap`.
- `mdwrap` reflows **one `inline` node at a time** (the real text of a
  paragraph or list item), skipping `fenced_code_block`,
  `indented_code_block`, `pipe_table`, `html_block` and headings. Ranges
  are applied bottom-up so line numbers stay valid. Formatting the whole
  `list` node at once does **not** work: nested list indentation breaks.
- The reflow runs in an **unattached scratch buffer**, and the result is
  written back with a single `nvim_buf_set_lines`. Do not move `gq` back
  onto the real buffer: every paragraph becomes its own buffer change, and
  each change costs a full Treesitter reparse of the document. On a
  504-line file that was 126 reparses — `:w` took 5.2s against 0.2s now.
  Profiling attributed it correctly: parse 0ms, range collection 2ms, `gq`
  loop 3.4s at 27ms per paragraph. Disabling autocmds, the LSP client or
  render-markdown changed nothing; only stopping Treesitter did. Doing it
  in a scratch buffer also makes the reflow one undo step instead of one
  per paragraph.
- Because the scratch buffer has no filetype, the options `gq` reads
  (`formatoptions`, `formatlistpat`, `comments`, indentation) are copied
  across explicitly. Setting `filetype` there instead would fire `FileType`
  and attach Treesitter again, undoing the whole point.
- Three traps solved in there, not to be reintroduced:
  - when an LSP server attaches it sets
    `formatexpr = v:lua.vim.lsp.formatexpr()`, so `gq` asks the server to
    format and `rumdl` does **not** wrap prose;
  - `nvim-treesitter` sets `indentexpr`, which `gq` uses to indent the
    lines it generates: the result is that only the first continuation line
    keeps the list indentation and the rest fall back to zero;
  - the markdown ftplugin puts `-`, `*` and `+` into `comments`, and with
    the `c`/`q` flags active `gq` treats them as comment markers and gets
    numbered-list indentation wrong: keep only `comments = "n:>"` for
    quotes and leave the rest to `formatlistpat` plus the `n` flag.
- Because of the first two, markdown buffers get `formatexpr` and
  `indentexpr` cleared on `LspAttach` and `BufWinEnter`, and again inside
  `M.wrap` for safety.
- `image.nvim` uses the `kitty` backend, which also covers WezTerm, and
  requires `imagemagick`.

## Spell checking

- Off everywhere by default. `:SpellToggle` / `<leader>z` enables it for
  the current buffer and session only; nothing is persisted.
- Several dictionaries apply at once (`spelllang = it,en`): a word passes
  if any of them contains it.
- Code exclusion needs both halves. Neovim's core queries provide
  `(inline) @spell`, which *adds* prose to the checker without excluding
  anything, and `(code_span) @nospell` for inline code. Fenced blocks are
  **not** covered by that: the injected language parser carries no spell
  capture, so `queries/markdown/highlights.scm` adds `@nospell` on
  `fenced_code_block` and `indented_code_block`. Do not remove it.
- Only `.spl` files are shipped. The `.sug` suggestion caches were dropped:
  `z=` works without them and the Italian one alone was 19.5 MB.
- Vim only publishes English under `runtime/spell/` in git; other languages
  come from the FTP mirrors. Use `curl -f` when fetching, or a 404 page
  lands in the file and Neovim reports `E757`.

## Build and checks

```sh
nix build            # build the package
nix run              # launch the editor
nix flake check
nix flake update     # refresh the lockfile
```

Useful during development:

```sh
nix eval .#packages.x86_64-linux.default.drvPath   # evaluate everything
selene init.lua lua/                               # lint lua
nixfmt module.nix flake.nix                        # format nix
nix build --dry-run .#default                      # download size
nix path-info --closure-size -h .#default          # build size
```

**After creating new files, `git add -A` before rebuilding**: flakes only
copy git-tracked files into the store, so a Lua module missing from the
index will not reach the package and the editor starts with
`module '...' not found`.

On the wrapper's `PATH`: `nixfmt`, `statix`, `deadnix` for Nix; `stylua`,
`selene` for Lua; `rumdl` for Markdown; `shellcheck`, `shfmt` for Bash.

## Code style

- Comments in **English**, short, and only at the points that need them.
- **Maximum 75 characters per comment line**, indentation included.
- Section headings:

  ```nix
  # SECTION NAME
  # ------------------------------------------------
  # --- Subsection name ---
  ```

  ```lua
  -- SECTION NAME
  --------------------------------------------------
  -- Subsection name --
  ```

- Markdown: 75-column lines, `-` for lists, ATX headings, fenced code
  blocks with triple backticks.

## Notes and traps

- `clipboard = unnamedplus`: the unnamed register is synced with `+`.
- `vim.o.exrc = true`: project-local `.nvim.lua` files are executed.
- `dankcolors.lua` is generated by **DankMaterialShell**, whose `matugen`
  theming derives the palette from the wallpaper: do not rename or move it.
  `init.lua` loads it separately and converts it on the fly
  (`RRethy/base16-nvim` → `base16-nvim`, `config` → `after`); the file
  contains a watcher that reloads the theme when it changes on disk.
- `vim.fn.stdpath("config")` points at `~/.config/nvim`, which a wrapper
  user usually does not have — the Lua config lives in the Nix store. Use
  `require("core.paths").config()` instead. **The one deliberate
  exception** is the `dankcolors.lua` lookup in `init.lua`: it must read
  the live file the shell rewrites, not the frozen store copy, which is
  exactly what lets the palette follow the desktop. Do not "fix" it.
- Some binaries are not in the build and come from the host: `git`, plus
  whatever the `settings.open.*` handlers point at.
- `nvim-lint` runs only on `BufReadPost` and `BufWritePost`: do not add
  `BufEnter` or `InsertLeave` back, it was a source of CPU spikes.
- Treesitter grammars come from Nix and are not compiled at runtime: to add
  one, edit the list in `module.nix`.
