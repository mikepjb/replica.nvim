local client = require("replica.client")
local clojure = require("replica.clojure")
local extract = require("replica.extract")
local log = require("replica.log")

-- TODO generally this namespace is becoming the central location for parts of the plugin to work together and should
-- be better organised.

local module = {}

module.client_instance = nil

-- TODO untested, I always use autoconnect at the moment
module.connect = function(args)
  local nrepl_port
  if args ~= nil and args["args"] ~= "" then
    nrepl_port = args["args"]
  else
    nrepl_port = clojure.discover_nrepl_port()
    if not nrepl_port then
      print("Please provide a port e.g Connect 8765")
      return
    end
  end

  local connection = module.connect({ host = host, port = port })
  module.clone(connection, "cljs_eval")
  module.clone(connection, "clj_eval")
  module.clone(connection, "main")

  client_instance = connection
end

module.cljs_connect = function(args)
  -- TODO we can try to find out if we are in a shadow or a figwheel project?
  -- for now assume figwheel (future, prefer shadow if see both)
  -- TODO also allow custom "hook" incase a new tool comes out and we don't support it yet!

  local figwheel = "(figwheel.main.api/cljs-repl \"dev\")"
  local hook = figwheel -- TODO will expand for shadow/custom from args later
  -- local cljs_connect_request = "(cider.piggieback/cljs-repl " .. hook .. ")"

  client.eval(module.client_instance, hook, { 
    session = module.client_instance.sessions.cljs_eval
  })
end

find_session = function()
  -- TODO also depends if CljEval? and if Piggieback is even connected?
  if clojure.is_cljs() then
    return module.client_instance.sessions.cljs_eval
  else
    return module.client_instance.sessions.clj_eval
  end
end

find_paths = function()
  return module.client_instance.paths
end

module.eval = function(args)
  if args["args"] ~= "" then -- :Eval <code> style
    return client.eval(module.client_instance, args["args"], {
      session = find_session(),
      ns = clojure.namespace(module.client_instance)
    })
  else
    local vlines = vim.api.nvim_buf_get_lines(0, args["line1"] - 1, args["line2"], true)
    local vline_string = ""
    for _, v in ipairs(vlines) do
      vline_string = vline_string .. v
    end
    -- TODO include lines?
    client.eval(module.client_instance, vline_string, {
      session = find_session(),
      ns = clojure.namespace(module.client_instance)
    })
  end
end

module.eval_last_sexp = function(args)
  local sexp = extract.form()
  client.eval(module.client_instance, sexp, { session=find_session(), ns=clojure.namespace(module.client_instance) })
end

module.quasi_repl = function()
  local ns = clojure.namespace(module.client_instance)
  local noerr, i = pcall(function()
    return vim.fn.input(ns .. "=> ")
  end)

  if noerr then
    client.eval(module.client_instance, i, { session=find_session(), ns=ns })
  end
end

module.doc = function(args)
  local subject
  if args ~= nil and args["args"] ~= "" then
    subject = args["args"]
  else
    subject = vim.fn.expand("<cword>")
  end
  client.doc(module.client_instance, subject, {
    session = module.client_instance.sessions.main, ns = clojure.namespace(module.client_instance)
  })
end

module.req = function(args)
  local ns = clojure.namespace(module.client_instance)
  local all_flag = ""

  if args and args["bang"] == true then
    all_flag = "-all"
  end

  local code = "(require '" .. ns .. " :reload" .. all_flag .. ")"
  client.eval(module.client_instance, code, { session = find_session() }, args.suppress_output)
end

module.test = function(args)
  local code = "(clojure.test/run-tests '" .. clojure.namespace(module.client_instance) .. ")"
  client.eval(module.client_instance, code, { session = module.client_instance.sessions.clj_test })
end

module.req_and_test = function(args)
  module.req({suppress_output = true})
  module.test()
end

module.req_bang_and_test = function(args)
  module.req({bang = true, suppress_output = true})
  module.test()
end

--   vim.api.nvim_create_user_command("Piggieback", function() client.piggieback("(figwheel.main.api/cljs-repl \"dev\")") end, {})

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

module.debug = function(args)
  print(vim.inspect(module.client_instance))
end

module.setup = function(client_instance)
  module.client_instance = client_instance
  -- TODO update/write documentation when you are happy with the set of commands
  vim.api.nvim_create_user_command("Require", module.req, { bang=true })
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?', range=true })
  vim.api.nvim_create_user_command("Test", module.test, { nargs='?', range=true })
  vim.api.nvim_create_user_command("Doc", module.doc, { nargs='?' })
  vim.api.nvim_create_user_command("CljsConnect", module.cljs_connect, { nargs='?' })
  -- TODO Prevent from being mapped outside debug mode?
  vim.api.nvim_create_user_command("Debug", module.debug, { nargs='?' })

  local bufopts = { noremap=true, silent=false }
   vim.keymap.set('n', 'cpp', module.eval_last_sexp, bufopts)
   vim.keymap.set('n', 'cpr', module.req_and_test, bufopts)
   vim.keymap.set('n', 'cpR', module.req_bang_and_test, bufopts)
   vim.keymap.set('n', 'cqp', module.quasi_repl, bufopts)
   vim.keymap.set('n', 'cpc', module.cljs_connect, bufopts) -- yeah? is this a good binding?
end

return module
