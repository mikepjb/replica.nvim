local client = require("replica.client")
local clojure = require("replica.clojure")
local extract = require("replica.extract")
local log = require("replica.log")
local util = require("replica.util")

local split = util.split

local module = {}

module.client_instance = nil

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

  module.client_instance = client.setup_connection(nrepl_port)
end

module.cljs_connect = function(args)
  local split_args = split(args["args"], "%S+")

  local profile = "\"dev\""
  local hook_fn = "figwheel.main.api/cljs-repl"

  if split_args[2] then
    profile = split_args[2]
  end

  if split_args[1] == "shadow" or split_args[1] == "shadow-cljs" then
    hook_fn = "shadow.cljs.devtools.api/repl"
  end

  local hook = "(" .. hook_fn .. " " .. profile .. ")"

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
  client.eval(module.client_instance, code, { session = find_session() }, client.empty_response)
end

module.test = function(args)
  local code = "(clojure.test/run-tests '" .. clojure.namespace(module.client_instance) .. ")"
  client.eval(module.client_instance, code, { session = module.client_instance.sessions.clj_test })
end

-- TODO if there is a syntax/compilation error we don't see it currently because output is suppressed!
module.req_and_test = function(args)
  module.req({suppress_output = true})
  module.test()
end

module.req_bang_and_test = function(args)
  module.req({bang = true, suppress_output = true})
  module.test()
end

module.history = function(args)
  log.history()
end

module.debug = function(args)
  print(vim.inspect(module.client_instance))
end

module.debug_range = function(args)
  local srow, scol, erow, ecol = extract.debug_range()
  print(vim.inspect({
    note = "remember these are 0-indexed and col/row nums are 1-indexed",
    srow = srow,
    scol = scol,
    erow = erow,
    ecol = ecol}))
  end

module.setup = function(client_instance, config)
  module.client_instance = client_instance
  -- TODO update/write documentation when you are happy with the set of commands
  vim.api.nvim_create_user_command("Require", module.req, { bang=true })
  vim.api.nvim_create_user_command("Eval", module.eval, { nargs='?', range=true })
  vim.api.nvim_create_user_command("Test", module.test, { nargs='?', range=true })
  vim.api.nvim_create_user_command("Doc", module.doc, { nargs='?' })
  vim.api.nvim_create_user_command("Connect", module.connect, { nargs='?' })
  vim.api.nvim_create_user_command("CljsConnect", module.cljs_connect, { nargs='?' })
  vim.api.nvim_create_user_command("History", module.history, { nargs='?' })

  if config.debug then
    vim.api.nvim_create_user_command("Debug", module.debug, { nargs='?' })
    vim.api.nvim_create_user_command("DRange", module.debug_range, { nargs='?' })
  end

  local bufopts = { noremap=true, silent=false }
   vim.keymap.set('n', 'cpp', module.eval_last_sexp, bufopts)
   vim.keymap.set('n', 'cpr', module.req_and_test, bufopts)
   vim.keymap.set('n', 'cpR', module.req_bang_and_test, bufopts)
   vim.keymap.set('n', 'cqp', module.quasi_repl, bufopts)
   vim.keymap.set('n', 'cpc', module.cljs_connect, bufopts) -- yeah? is this a good binding?
end

return module
