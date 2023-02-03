# Replica.nvim

Yet another REPL interaction plugin for neovim.

Written in Lua, this project aims to be:

- Simple in terms of features:
  - REPL interaction via neovim's command line
  - REPL interaction via the buffer with fireplace-style normal mode keys e.g `cpr` `cpp`
  - Self-contained package, no external dependencies that make this hard to use
  - Omni-completion
  - Support for multiple REPLs e.g Clojure & Clojurescript.
    - Support for a .dir-locals.el style file for project specific commands like Emacs.

For lisp editing see `vim-sexp` or the sister project for Replica: `parengage.nvim`

# Special thanks

Thank you octo.nvim for being a great reference for writing lua based neovim plugins!
