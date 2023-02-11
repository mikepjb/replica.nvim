local client = require("replica.client")
local clojure = require("replica.clojure")
local extract = require("replica.extract")
local log = require("replica.log")

-- TODO generally this namespace is becoming the central location for parts of the plugin to work together and should
-- be better organised.

local module = {}

module.client_instance = nil

-- module.connect = function(args)
--   if args ~= nil and args["args"] ~= "" then
--     client.connect("127.0.0.1", args["args"])
--   else
--     -- TODO filereadable succeeds even if the file is not around, needs fixing.
--     -- if vim.fn.filereadable(".nrepl-port") then
--     -- TODO I don't like that this uses io.open and then vim.fn.readfile seperately..
--     local port_file = io.open(".nrepl-port", r)
--     if port_file ~= nil then
--       local nrepl_port = tonumber(vim.fn.readfile(".nrepl-port")[1])
--       client.connect("127.0.0.1", nrepl_port)
--     else
--       print("Please provide a port e.g Connect 8765")
--     end
--   end
-- end

module.eval = function(args)
  if args["args"] ~= "" then -- :Eval <code> style
    return client.eval(module.client_instance, args["args"], {
      session = module.client_instance.sessions.clj_eval,
      ns = clojure.namespace()
    })
  else
    local vlines = vim.api.nvim_buf_get_lines(0, args["line1"] - 1, args["line2"], true)
    local vline_string = ""
    for _, v in ipairs(vlines) do
      vline_string = vline_string .. v
    end
    client.eval(module.client_instance, vline_string, {
      session = module.client_instance.sessions.clj_eval,
      ns = clojure.namespace()
    })
  end
end

-- module.eval_last_sexp = function(args)
--   local sexp = extract.form()
--   client.eval(sexp, { ns=clojure.namespace() })
-- end
-- 
-- module.quasi_repl = function()
--   local ns = clojure.namespace()
--   -- TODO we use pcall/protected call to "eat" C-c/aborting behaviour by the user but this also seems to result in the
--   -- first stdout message being 'invisible' e.g (println "ok") should return nil, and it does but only after the first
--   -- call.
--   local noerr, i = pcall(function()
--     return vim.fn.input(ns .. "=> ")
--   end)
-- 
--   if noerr then
--     client.eval(i, { ns=ns })
--   end
--   -- local i = vim.fn.input(ns .. "=> ")
--   -- client.eval(i, { ns=ns })
-- end
-- 
-- module.doc = function(args)
--   client.doc(clojure.namespace(), vim.fn.expand("<cword>"))
-- end
-- 
-- module.run_tests = function(args)
--   print("nope!")
-- end
-- 
-- module.req = function(args)
--   if args["bang"] == true then
--     client.req(clojure.namespace(), true)
--   else
--     client.req(clojure.namespace())
--   end
-- end
-- 
-- module.req_and_tests = function(args)
--   module.req()
--   module.run_tests()
-- end
-- 
-- module.req_all_and_tests = function(args)
--   module.req({bang=true})
--   module.run_tests()
-- end
-- 
-- module.describe = function()
--   client.describe()
-- end
-- 
-- module.test_args = function(args)
--   print(vim.inspect(args))
-- end
-- 
-- module.setup = function()
--   -- Completed functions
--   vim.api.nvim_create_user_command("Connect", module.connect, { nargs='?' })
--   -- TODO in Emacs, jack-in fns actually start an nREPL process too. should we do the same?
--   vim.api.nvim_create_user_command("JackIn", module.connect, { nargs='?' })
--   vim.api.nvim_create_user_command("Doc", module.doc, { nargs='?' })
--   vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?', range=true })
--   -- Require! I think the ! actually becomes an arg?
--   vim.api.nvim_create_user_command("Require", module.req, { bang=true })
--   vim.api.nvim_create_user_command("RDescribe", module.describe, {})
--   vim.api.nvim_create_user_command("RunTests", module.run_tests, {})
-- 
--   -- Completed bindings
--   -- TODO these should be user configurable.
--   -- TODO we may want to specify buffers this is applicable to, see on_attach buffer option for lsp config in mikepjb's
--   -- init.lua
--   local bufopts = { noremap=true, silent=false }
--   -- vim.keymap.set('n', 'cpp', module.eval_last_sexp, bufopts)
--   -- TODO vim.keymap.set('n', 'cpr', module.eval_last_sexp, bufopts)
--   -- cpr => Require & RunTests
--   vim.keymap.set('n', 'cpn', module.connect, bufopts)
--   vim.keymap.set('n', 'cpr', module.req_and_tests, bufopts)
--   vim.keymap.set('n', 'cpR', module.req_all_and_tests, bufopts)
-- 
--   -- vim.g.operatorfunc = function(args)
--   --   log.debug(args)
--   -- end
-- 
--   -- TODO https://github.com/tpope/vim-fireplace/blob/614622790b9dbe2d5a47b435b01accddf17be3e6/autoload/fireplace.vim#L1809
--   vim.keymap.set('n', 'cpp', module.eval_last_sexp, bufopts)
--   vim.keymap.set('n', 'cqp', module.quasi_repl, bufopts)
-- 
--   -- WIP functions
--   -- TODO get this working!
--   -- vim.cmd([[command! JackInCljs :CljEval (figwheel.main.api/cljs-repl "dev")<cr>]])
--   vim.api.nvim_create_user_command("JackInShadowCljs", function () client.eval("(shadow.cljs.devtools.api/repl :app-dev)") end, {})
--   vim.api.nvim_create_user_command("JackInFigwheelCljs", function () client.eval("(figwheel.main.api/cljs-repl \"dev\")") end, {})
--   vim.api.nvim_create_user_command("Piggieback", function() client.piggieback("(figwheel.main.api/cljs-repl \"dev\")") end, {})
-- 
--   -- TODO should be a dwim function that figures out which adaptor you are using and connects.
--   -- vim.api.nvim_create_user_command("JackInCljs", function () client.eval("(shadow.cljs.devtools.api/repl :app-dev)") end, {})
--   -- vim.cmd([[command! SJackInCljs :CljEval (shadow.cljs.devtools.api/repl :app-dev)<cr>]])
-- 
--   -- Test functions
--   vim.api.nvim_create_user_command("TestArgs", module.test_args, { nargs='?' })
--   vim.api.nvim_create_user_command("TestMessage", function () client.eval("(+ 40 2)") end, {})
-- 
--   if not client.connected() then
--     module.connect()
--   end
-- end

module.setup = function(client_instance)
  module.client_instance = client_instance
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?', range=true })
end

return module
