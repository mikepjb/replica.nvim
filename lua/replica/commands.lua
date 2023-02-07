local client = require("replica.client")
local clojure = require("replica.clojure")
local log = require("replica.log")

local module = {}

module.connect = function(args)
  if args["args"] ~= "" then
    client.connect("127.0.0.1", args["args"])
  else
    if vim.fn.filereadable(".nrepl-port") then
      local nrepl_port = tonumber(vim.fn.readfile(".nrepl-port")[1])
      client.connect("127.0.0.1", nrepl_port)
    else
      print("Please provide a port e.g Connect 8765")
    end
  end
end

module.eval = function(args)
  log.debug(vim.inspect(args))
  if args["args"] ~= "" then -- :Eval <code> style eval, do not include lines
    client.eval(args["args"], { ns=clojure.namespace() })
  else
    local vlines = vim.api.nvim_buf_get_lines(0, args["line1"] - 1, args["line2"], true)
    local vline_string = ""
    for _, v in ipairs(vlines) do
      vline_string = vline_string .. v
    end
    client.eval(vline_string, { ns=clojure.namespace() })
  end
end

module.eval_last_sexp = function(args)
  -- TODO not implemented!
  print(vim.inspect(args))
  -- client.eval()
end

module.doc = function(args)
  client.doc(clojure.namespace(), vim.fn.expand("<cword>"))
end

module.req = function(args)
  if args["bang"] == true then
    client.req(clojure.namespace(), true)
  else
    client.req(clojure.namespace())
  end
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
  vim.api.nvim_create_user_command("Doc", module.doc, { nargs='?' })
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?', range=true })
  -- Require! I think the ! actually becomes an arg?
  vim.api.nvim_create_user_command("Require", module.req, { bang=true })
  vim.api.nvim_create_user_command("RDescribe", module.describe, {})

  -- Completed bindings
  -- TODO these should be user configurable.
  -- TODO we may want to specify buffers this is applicable to, see on_attach buffer option for lsp config in mikepjb's
  -- init.lua
  local bufopts = { noremap=true, silent=false }
  -- vim.keymap.set('n', 'cpp', module.eval_last_sexp, bufopts)
  -- TODO vim.keymap.set('n', 'cpr', module.eval_last_sexp, bufopts)

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
