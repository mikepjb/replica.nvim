## :fire: replica.nvim

Yet another REPL interaction plugin for neovim.

Written in Lua, this project aims to be:

- Simple in terms of features:
  - [X] REPL interaction via neovim's command line
  - [ ] REPL interaction via the buffer with fireplace-style normal mode keys e.g `cpr` `cpp`
  - [X] Self-contained package, no external dependencies that make this hard to use
  - [ ] Omni-completion
  - [ ] Support for multiple REPLs e.g Clojure & Clojurescript.
    - Test support for both shadow-cljs/figwheel
    - Support for a .dir-locals.el style file for project specific commands like Emacs.
  - [ ] Require on save?
    - optional disable?

For lisp editing see `vim-sexp` or the sister project for Replica: `parengage.nvim`

## :mechanical_arm: Installation

You can install this plugin using packer or any of the other great plugin managers, here's an example for packer:
```
require('packer').startup(function(use)
    use 'mikepjb/replica.nvim'
end)
```

## :open_book: Configuration

Configuration can be done from either `lua` or `viml`:

```
Actually not yet, but this is planned!
```

## :beetle: Known Bugs

- replica.nvim does not know if the nREPL process has stopped running, you can continue to issue `:Eval` after
  successfully connecting and there will be no response in the UI.
## :test_tube: Testing

`make test` though make sure you have `plenary.nvim` installed next to this project (e.g both in the same src folder
`src/replica.nvim` and `src/plenary.nvim`

## :heart: Special thanks

- Thank you tpope (& other contributors) for making fireplace.vim
- Thank you octo.nvim for being a great reference for writing lua based neovim plugins!
- Thank you also to the neovim team for nice documentation, especially on the vim.loop/libuv integration!
