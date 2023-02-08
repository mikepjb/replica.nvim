local bencode = require("replica.bencode")
local clojure = require("replica.clojure")
local log = require("replica.log")

local decode, encode = bencode.decode, bencode.encode
local insert, concat = table.insert, table.concat

-- TODO allow this to be controlled via config
local debug = true
local debug_eval_only = true -- only print full message for the eval session

local module = {}

-- nREPL reference, including best practices: https://nrepl.org/nrepl/building_clients.html TODO keep evals in one
-- session and tooling-related evaluations (e.g for code completion) in another to avoid *1 and *e from being messed
-- up.

-- Learning notes: if you have a uv__check_before_write error, make sure you aren't trying to sent tables over the
-- wire. This can happen if you aren't bencoding messages first.

local tcp_client -- TCP client for sending messages
local sessions = {} -- typically we have "main", "eval" and sometimes "cljs" sessions
local next_session = "main"
local id = "replica.client"
local partial_chunks = nil

module.piggieback = function(hook)
  clone("cljs")
  module.eval("(cider.piggieback/cljs-repl " .. hook .. ")", {session=sessions["cljs"]})
end

module.connected = function()
  return tcp_client ~= nil
end

-- TODO make sure this is used for all relevant fns (everything except connect?)
pre_execution_checks = function()
  -- TODO are we in a clj/cljs file & do we have access to the right REPL type?
  -- TODO do we still have a REPL that we can connect to?
end

module.doc = function(ns, sym)
  -- TODO requires cider-middleware info command
  tcp_client:write(encode({op="info", ns=ns, sym=sym}))
end

clone = function(new_session)
  next_session = new_session or "main"
  original_session_id = sessions[next_session]

  -- always branch off the main session
  if sessions["main"] then
    tcp_client:write(encode({op="clone", session=sessions["main"]}))
  else
    tcp_client:write(encode({op="clone"}))
  end
end

-- TODO should be in a string util module? what else can be grouped with this? I want to try and avoid a "util"
-- uncategoised module.
-- multiline errors end with a newline, causing the user the hit enter twice to move on.
trim = function(s)
  return string.gsub(s, "%s+$", "")
end

-- internal function for reading messages that come back from the nREPL.
read = function(chunk)
  local message, _

  if partial_chunks == nil then
    message, _ = decode(chunk)
  else
    message, _ = decode(concat(partial_chunks) .. chunk)
  end
  if debug then
    log.debug(vim.inspect(message))
  end

  if message == nil then
    -- in this case, the chunk is not parseable which probably means we have part of a big message.
    if partial_chunks == nil then
      partial_chunks = {}
    end
    insert(partial_chunks, chunk)
  else
    partial_chunks = {} -- reset as we have a full parsed message

    if message["new-session"] ~= nil then
      sessions[next_session] = message["new-session"]
      log.debug(next_session .. " session id set as: ".. sessions[next_session])
      log.debug("all sessions:\n" .. vim.inspect(sessions))
      next_session = "main"
    end

    if message["doc"] ~= nil then
      local doc_message = (message["ns"] .. "/" .. message["name"] .. "\n" .. message["arglists-str"] .. "\n" .. message["doc"] .. "\n" .. message["file"])
      vim.schedule(function()
        vim.notify(trim(doc_message), vim.log.levels.INFO)
      end)
    end

    if message["session"] == sessions["eval"] or
      message["session"] == sessions["cljs"] then
      if debug_eval_only then
        log.debug(vim.inspect(message))
      end
      if message["value"] ~= nil then
        -- TODO really should be writing to a temp buffer also?
        log.debug(message["value"])
        print(message["value"])
      end

      -- For stdout commands such as clojure.core/println
      if message["out"] ~= nil then
        -- TODO really should be writing to a temp buffer also?
        log.debug(message["out"])
        print(message["out"])
      end


      -- TODO do we really want this?
      -- if message["ex"] ~= nil then -- Clojure(script) eval exception
      --   print(message["status"] .. "\n" message["ex"]
      -- end

      if message["err"] ~= nil then
        log.debug(message["err"])
        vim.schedule(function()
          vim.notify(trim(message["err"]), vim.log.levels.ERROR)
        end)
      end
    end
  end
end

module.disconnect = function()
  if tcp_client then
    if not tcp_client:is_closing() then
      tcp_client:read_stop()
      tcp_client:shutdown()
      tcp_client:close()
    end
    tcp_client = nil
    sessions = {}
    log.debug("Client found & disconnected")
  else
    print("Could not find a connection to disconnect!")
  end
end

-- TODO find port based on .nrepl-port?
module.connect = function(host, port)
  if tcp_client then
    module.disconnect()
  end

  local uv = vim.loop
  tcp_client = uv.new_tcp()
  local connection = uv.tcp_connect(tcp_client, host, port, function(err)
    if err then
      print("Could not find an nREPL to connect to on port " .. port)
      log.debug(err)
    else
      clone("main") -- for a new main session id
      clone("eval") -- for a seperate eval session id
    end
  end)

  tcp_client:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      read(chunk)
    else
      tcp_client:shutdown()
      tcp_client:close()
    end
  end)
end

-- TODO we want to fail gracefully if the user tries to use a command without being connected first
-- TODO ideally this is done by wrapping all fns to avoid extra code.. but maybe it's better just to be explicit about
-- this?
-- module.check_connection = function()
--   return tcp_client ~= nil
-- end

module.eval = function(code, opts)
  local filename = vim.fn.expand('%:t')
  local session = sessions["eval"]

  if string.find(filename, ".cljs") then
    if sessions["cljs"] then
      session = sessions["cljs"]
    else
      vim.schedule(function()
        vim.notify("No Clojurescript REPL available", vim.log.levels.ERROR)
      end)
      return
    end
  end

  local message = { id=id, op="eval", code=code, session=session }

  if opts ~= nil then
    for k, v in pairs(opts) do
      message[k] = v
    end
  end

  log.debug(message)
  tcp_client:write(encode(message))
end

module.req = function(ns, all)
  -- get text from current buffer
  -- get current file
  local all_flag = all and "-all" or ""
  local code = "(require '" .. ns .. " :reload" .. all_flag .. ")"
  log.debug("require: " .. code)
  tcp_client:write(encode({ id=id, op="eval", code=code, session=sessions["eval"] }))
end

module.describe = function()
  tcp_client:write(encode({id=id, op="describe", session=sessions["eval"] }))
end

return module
