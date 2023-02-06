local client = require("replica.client")

local module = {}

module.eval = function(args)
  if args["args"] ~= "" then
    client.eval(args["args"])
  end
end

module.connect = function(args)
  if args["args"] ~= "" then
    client.connect("127.0.0.1", args["args"])
    print("Connected to " .. args["args"])
  else
    print("Please provide a port e.g Connect 8765")
  end
end

module.test_args = function(args)
  print(vim.inspect(args))
end

module.setup = function()
  vim.api.nvim_create_user_command("Connect", module.connect, { nargs='?' })
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?' })
  vim.api.nvim_create_user_command("TestArgs", module.test_args, { nargs='?' })
  vim.api.nvim_create_user_command("TestMessage", function () client.eval("(+ 40 2)") end, {})
end

return module
