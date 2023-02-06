local client = require("replica.client")

local module = {}

module.connect = function(args)
  if args["args"] ~= "" then
    client.connect("127.0.0.1", args["args"])
  else
    print("Please provide a port e.g Connect 8765")
  end
end

module.eval = function(args)
  if args["args"] ~= "" then
    client.eval(args["args"])
  end
end

module.req = function(args)
  -- TODO get ns! it's not always user you fool.
  client.req("user")
end

module.describe = function()
  client.describe()
end

module.test_args = function(args)
  print(vim.inspect(args))
end

module.setup = function()
  -- Completed functions
  vim.api.nvim_create_user_command("Connect", module.connect, { nargs='?' })
  vim.api.nvim_create_user_command("JackIn", module.connect, { nargs='?' })
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?' })
  vim.api.nvim_create_user_command("Require", module.req, {})
  vim.api.nvim_create_user_command("RDescribe", module.describe, {})
  -- TODO load file? is the same as require?
  -- it's not the same
  -- vim.api.nvim_create_user_command("RLoadFile", module.describe, {})

  -- WIP functions
  -- TODO get this working!
  -- vim.cmd([[command! JackInCljs :CljEval (figwheel.main.api/cljs-repl "dev")<cr>]])
  vim.api.nvim_create_user_command("JackInShadowCljs", function () client.eval("(shadow.cljs.devtools.api/repl :app-dev)") end, {})
  vim.api.nvim_create_user_command("JackInFigwheelCljs", function () client.eval("(figwheel.main.api/cljs-repl \"dev\")") end, {})
  -- TODO should be a dwim function that figures out which adaptor you are using and connects.
  -- vim.api.nvim_create_user_command("JackInCljs", function () client.eval("(shadow.cljs.devtools.api/repl :app-dev)") end, {})
  -- vim.cmd([[command! SJackInCljs :CljEval (shadow.cljs.devtools.api/repl :app-dev)<cr>]])

  -- Test functions
  vim.api.nvim_create_user_command("TestArgs", module.test_args, { nargs='?' })
  vim.api.nvim_create_user_command("TestMessage", function () client.eval("(+ 40 2)") end, {})
end

return module
