local commands = require("replica.commands")
local client = require("replica.client")
local util = require("replica.util")

local merge = util.merge

local module = {}

module.auto_connect = true -- TODO always true, make confugrable

module.setup = function(user_config)
  if not vim.fn.has "nvim-0.7" then
    utils.error "replica.nvim requires neovim 0.7+"
    return
  end

  local default_config = {
    auto_connect = true,
    debug = false, -- TODO not yet used, how best to pass around config?
    print_location = "preview" -- choice of preview if too big? preview always? Ex always? buffer?
  }

  local config = merge(default_config, user_config)
  local client_instance = nil

  if config.auto_connect then
    client_instance = client.setup()
  end

  commands.setup(client_instance, config)
end

return module
