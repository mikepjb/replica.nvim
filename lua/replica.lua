local commands = require("replica.commands")
local client = require("replica.client")
local util = require("replica.util")
local log = require("replica.log")

local merge = util.merge


local module = {}

-- TODO check that connection is available before issuing commands!
module.setup = function(user_config)
  if not vim.fn.has "nvim-0.7" then
    utils.error "replica.nvim requires neovim 0.7+"
    return
  end

  local default_config = {
    auto_connect = false,
    debug = false,
    print_location = "preview" -- choice of preview if too big? preview always? Ex always? buffer?
  }

  local config = merge(default_config, user_config)

  log.setup(config)

  local client_instance = client.setup(config)
  commands.setup(client_instance, config)
end

return module
