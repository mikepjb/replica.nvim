local client = require("replica.client")

local module = {}

module.setup = function()
  vim.api.nvim_create_user_command("Connect", function() client.connect("127.0.0.1", 54038) end, {})
  vim.api.nvim_create_user_command("TestMessage", function () client.eval("user", "(+ 40 2)") end, {})
end

return module
