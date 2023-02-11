local commands = require("replica.commands")
local client = require("replica.client")

local module = {}

module.auto_connect = true -- TODO always true, make confugrable

module.setup = function(config)
  if not vim.fn.has "nvim-0.7" then
    utils.error "replica.nvim requires neovim 0.7+"
    return
  end

  local client_instance = nil

  -- TODO need to not autoconnect for testing or we start spawning lots of clients?
  if module.auto_connect then
    client_instance = client.setup()
  end

  commands.setup(client_instance)
end

return module
