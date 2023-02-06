local client = require("replica.client")

local module = {}

-- Learning for nREPL
--
-- neovim has a stdlib assigned as the 'vim' module
--
-- The loop exposes all the features of the Nvim event-loop, of which there are some TCP commands
-- tcp_connect
-- tcp_open
-- etc.
-- https://neovim.io/doc/user/luvref.html#luv-intro
-- lua print(vim.inspect(vim.loop))

-- TODO having a module.client won't work for multiple nREPL connections, maybe we will need a collection of
-- connections for clj and cljs to connect at the same time?
-- XXX answer: I think we have a single TCP connection and grab 2 sessions?

module.setup = function()
  -- local cmd = nvim_create_user_command

  -- cmd("Connect" 'echo "Hello world!"', {})
  -- vim.api.nvim_create_user_command("Connect", 'echo "Hello world!"', {})
  vim.api.nvim_create_user_command("Connect", function() client.connect("127.0.0.1", 54038) end, {})
  vim.api.nvim_create_user_command("Clone", client.clone, {})
  vim.api.nvim_create_user_command("TestMessage", function () client.eval("(+ 40 2)") end, {})
end

return module
