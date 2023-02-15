## :fire: replica.nvim

_Also currently alpha quality, I use this for development and will update this notice when I think it's ready for others to try out for their own workflows._

A REPL interaction tool for neovim.

## :dart: Features

Written in Lua, this project aims to be simple in terms of features:

- [X] REPL interaction via neovim's command line with `:Eval <code>` and `:Eval` with visual mode.
- [X] Automatically attempt to connect to an nREPL (based on `.nrepl-port`)
- [ ] include REPL access
  - [ ] include REPL history
  - [ ] readline controls (or at least persist user set bindings) e.g `C-a/e`
- [ ] REPL interaction via the buffer with fireplace-style normal mode keys e.g `cpr` `cpp`
  - [X] `cpp` eval/print last or current sexp
  - [X] `cpn` connect to an nrepl (via `.nrepl-port`)
  - [X] `cpr` reload namespace and run tests
  - [X] `cpR` hard reload namespace and run tests
  - [ ] `cm` `cqq` `cqp` `cqc` `<C-R(`?
- [X] Self-contained package, no external dependencies that make this hard to use
- [X] `:Doc <search_term>`
- [ ] Omni-completion
- [ ] Support for multiple REPLs e.g Clojure & Clojurescript.
  - Test support for both shadow-cljs/figwheel
  - Support for a .dir-locals.el style file for project specific commands like Emacs.
- [ ] Require on save
  - option to disable this
- [ ] Make sure TODOs/XXX are documented and addressed before v1 release!
- [ ] when all are addressed, remove tick boxes!

Non-Requirements (some are likely going to be put into parengage):
  - [ ] elastic parens (e.g creating closing parens)

For lisp editing see `vim-sexp` or the sister project for Replica: `parengage.nvim`

To reduce the amount this plugin has to do, we use cider-middleware to support some of our functions (which ones?) _needs expansion_

- LSP is good for doc/K, maybe have simple info and recommend a setup for that instead?
  - neovim lsp client + clojure-lsp does a good job. but certain things are missing
    - e.g hovering K on figwheel/stop-all does not show the docs for this
  - Problem here is that `clojure-lsp` won't pick up dependencies for aliases, so if you include them in say `client` for client stuff then you're stuffed.

## :grey_question: Why?/FAQs

### Why Neovim?

- Reason #1 is the busted/plenary testing framework which you can use to drive a real neovim instance, to help prevent
broken plugins.
- Lua is slight easier to program in than VimL but not by much, we're really here for the testing framework!

### Why another Vim REPL plugin?

- fireplace.vim is an awesome tool, (as is acid/conjure/iced.vim) but fireplace is really nice to use. We want to have
  a plugin like it, that can also take advantage of a solid testing framework and asynchronous editor architecture that
  allows us to interact with cider in ways that weren't that practical before (though we don't do that yet!)

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
require('packer').startup(function(use)
  use { 'mikepjb/replica.nvim',
    run = function() require('replica').setup({
      auto_connect = true,
      debug = true
    }) end,
  }
end)
```

## :beetle: Known Bugs

- replica.nvim does not know if the nREPL process has stopped running, you can continue to issue `:Eval` after
  successfully connecting and there will be no response in the UI.
- [8th Feb] it's possible that the sessions need to be closed to avoid OOMing? Needs more investigation

## :test_tube: Testing

`make test` though make sure you have `plenary.nvim` installed next to this project (e.g both in the same src folder
`src/replica.nvim` and `src/plenary.nvim`

## :heart: Special thanks

- Thank you [Dominic/SevereOverfl0w](https://github.com/SevereOverfl0w) for vim-replant and discussing this project
- Thank you Bozhidar (& other contributors) for making cider
- Thank you tpope (& other contributors) for making fireplace.vim
- Thank you octo.nvim for being a great reference for writing lua based neovim plugins!
- Thank you also to the neovim team for nice documentation, especially on the vim.loop/libuv integration!
