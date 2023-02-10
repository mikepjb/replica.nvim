local commands = require("replica.commands")
local client = require("replica.client")

local module = {}

module.setup = function(config)
  if not vim.fn.has "nvim-0.7" then
    utils.error "replica.nvim requires neovim 0.7+"
    return
  end

  -- TODO need to not autoconnect for testing or we start spawning lots of clients?
  -- if autoconnect == nil {
  -- }

  client.setup()
  commands.setup()
end

return module
