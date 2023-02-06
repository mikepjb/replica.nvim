local client = require("replica.client")

local module = {}

module.eval = function(args)
  if args["args"] ~= "" then
    client.eval(args["args"])
  end
end

module.test_args = function(args)
  print(vim.inspect(args))
end

module.setup = function()
  vim.api.nvim_create_user_command("Connect", function() client.connect("127.0.0.1", 54038) end, {})
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?' })
  vim.api.nvim_create_user_command("TestArgs", module.test_args, { nargs='?' })
  vim.api.nvim_create_user_command("TestMessage", function () client.eval("(+ 40 2)") end, {})
end

return module
