local bencode = require("replica.bencode")
local network = require("replica.network")
local clojure = require("replica.clojure")
local log = require("replica.log")

-- TODO potentially needs a rewrite in socket instead of tcp client?

-- TODO imports from untested
local decode, encode = bencode.decode, bencode.encode
local insert, concat, remove = table.insert, table.concat, table.remove

-- new imports
local uv = vim.loop
local insert = table.insert
local decoder, encode = bencode.decoder, bencode.encode

local module = {}

module.send = function(connection, message, callback, prompt)
  log.debug("send: " .. message)
  insert(connection.queue, 1, (callback or false))
  -- TODO handle prompt?
  connection.socket:write(encode(message))
end

module.connect = function(opts)
  local handle_message = function(err, chunk)
    opts.on_error(err)

    local messages = connection.decode(chunk)

    for _, m in ipairs(messages) do
      vim.notify(m, vim.log.levels.INFO)
    end
  end

  local connection = {
    decode = decoder(),
    queue = {},
    on_failure = function (err)
      vim.notify(err, vim.log.levels.ERROR)
    end,
    on_success = function ()
      vim.notify("Connected!", vim.log.levels.INFO)
    end,
    socket = network.connect(opts.host, opts.port, function (err)
      -- it is an error to invoke vim.api inside vim.loop callbacks, schedule_wrap defers these calls.
      vim.schedule_wrap(function (err)
        if err then
          connection.on_failure(err)
        else
          connection.socket:read_start(function (err, chunk)
            vim.schedule_wrap(function (err)
              handle_message(err, chunk)
            end)
          end)
        end
      end)
      -- callback with nothing
    end)
  }

  return connection
end
-- -----------------------------------------------------------
-- old/untested below
-- -----------------------------------------------------------
local old_module = {}

-- nREPL reference, including best practices: https://nrepl.org/nrepl/building_clients.html TODO keep evals in one
-- session and tooling-related evaluations (e.g for code completion) in another to avoid *1 and *e from being messed
-- up.

local debug = true -- TODO allow this to be controlled via config
local tcp_client -- TCP client for sending messages
local sessions = {} -- typically we have "main", "eval" and sometimes "cljs" sessions
local session_queue = {}
local id = "replica.client"
local partial_chunks = nil

module.piggieback = function(hook)
  module.eval("(cider.piggieback/cljs-repl " .. hook .. ")", { session=sessions["replica.cljs"] })
end

module.connected = function()
  return tcp_client ~= nil
end

-- TODO make sure this is used for all relevant fns (everything except connect?)
pre_execution_checks = function()
  -- TODO are we in a clj/cljs file & do we have access to the right REPL type?
  -- TODO do we still have a REPL that we can connect to?
end

-- TODO requires cider-middleware info command
module.doc = function(ns, sym)
  tcp_client:write(encode({op="info", ns=ns, sym=sym}))
end

-- TODO should we always branch off the main session
-- the default behaviour here is to create a new session with default bindings
clone = function(new_session)
  local next_session = new_session or "replica.main"
  insert(session_queue, next_session)
  tcp_client:write(encode({op="clone"}))
end

-- TODO should be in a string util module? what else can be grouped with this? I want to try and avoid a "util"
-- uncategoised module.
-- multiline errors end with a newline, causing the user the hit enter twice to move on.
trim = function(s)
  s, _ = string.gsub(s, "%s+$", "")
  return s
end

-- internal function for reading messages that come back from the nREPL.
read = function(chunk)


  ---- old
  local message, _

  if partial_chunks == nil then
    message, _ = decode(chunk)
  else
    message, _ = decode(concat(partial_chunks) .. chunk)
  end

  if debug then
    if message and message["changed-namespaces"] == nil then
      log.debug(vim.inspect(message))
    elseif message and message["changed-namespaces"] ~= nil then
      log.debug("changed-namespaces message received (but suppressed from logs)")
    end
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
      local next_session = session_queue[1]
      sessions[next_session] = message["new-session"]
      log.debug(next_session .. " session id set as: ".. sessions[next_session])
      log.debug("all sessions:\n" .. vim.inspect(sessions))
      remove(session_queue, 1)
      log.debug("new session_queue:\n" .. vim.inspect(session_queue))
    end

    if message["doc"] ~= nil then
      local doc_message = (message["ns"] .. "/" .. message["name"] .. "\n" .. message["arglists-str"] .. "\n" .. message["doc"] .. "\n" .. message["file"])
      vim.schedule(function()
        vim.notify(trim(doc_message), vim.log.levels.INFO)
      end)
    end

    if message["session"] == sessions["replica.eval"] or
      message["session"] == sessions["replica.cljs"] then
      if message["value"] ~= nil then
        -- TODO really should be writing to a temp buffer also?
        log.debug(message["value"])
        print(trim(message["value"]))
      end

      -- For stdout commands such as clojure.core/println
      if message["out"] ~= nil then
        -- TODO really should be writing to a temp buffer also?
        log.debug(message["out"])
        print(trim(message["out"]))
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

module.old_disconnect = function()
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
module.old_connect = function(host, port)
  if tcp_client then
    module.disconnect()
  end

  local uv = vim.loop
  tcp_client = uv.new_tcp()
  local connection = uv.tcp_connect(tcp_client, host, port, function(err)
    -- N.B 
    if err then
      print("Could not find an nREPL to connect to on port " .. port)
      log.debug(err)
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

  -- TODO sometimes replica.main is not set, seems like there is a race condition here..
  -- when replica.main isn't set, cljs works? no protocol error?
  -- sleeping does not resolve the issue anyway
  clone("replica.main") -- for a new main session id
 -- TODO this seems to solve the problem, oh boy. Ideally we don't want to use sleep to make sure these calls are not
 -- interfering with each other.
  uv.sleep(5)
  clone("replica.eval") -- for user-driven evaluations
  uv.sleep(5)
  clone("replica.cljs") -- for user-driven evaluations
end

-- TODO we want to fail gracefully if the user tries to use a command without being connected first
-- TODO ideally this is done by wrapping all fns to avoid extra code.. but maybe it's better just to be explicit about
-- this?
-- module.check_connection = function()
--   return tcp_client ~= nil
-- end

module.eval = function(code, opts)
  local filename = vim.fn.expand('%:t')
  local session = sessions[opts["session"]] or sessions["replica.eval"]
  -- log.debug("XXX")
  -- log.debug(session)
  -- log.debug(opts)
  -- log.debug("\n")

  if string.find(filename, ".cljs") then
    -- TODO also need to cover calling :CljEval or :Piggieback in an active cljs buffer
    if sessions["replica.cljs"] then
      session = sessions["replica.cljs"]
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
  tcp_client:write(encode({ id=id, op="eval", code=code, session=sessions["replica.main"] }))
end

module.describe = function()
  tcp_client:write(encode({id=id, op="describe", session=sessions["replica.main"] }))
end

return module
