local commands = require "replica.commands"

local module = {}

module.setup = function(config)
  if not vim.fn.has "nvim-0.7" then
    utils.error "replica.nvim requires neovim 0.7+"
    return
  end

  commands.setup()
end

return module
