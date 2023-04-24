local bencode = require("replica.bencode")
local network = require("replica.network")
local clojure = require("replica.clojure")
local log = require("replica.log")
local util = require("replica.util")

local uv = vim.loop
local insert, concat = table.insert, table.concat
local decoder, encode = bencode.decoder, bencode.encode
local merge, contains = util.merge, util.contains
local gsub = string.gsub

local module = {}

-- TODO generally speaking there are no user alerts for cljs repl missing/no client connected
-- TODO there is no immediate user feedback e.g (start-figwheel) shows no response, you don't even know you triggered
-- it tbh.. maybe show user feedback by default but make it configurable?

module.clone = function(connection, name)
  local name = name or "main"
  network.send(connection, {op="clone"}, function(m)
    if m and m["new-session"] then
      connection.sessions[name] = m["new-session"]
    end
  end, false)
end

module.doc = function(connection, sym, opts)
  local opts = opts or {}
  network.send(connection, merge({op = "info", sym = sym}, opts), function(m)
    log.info((m.ns .. "/" .. m.name) .. "\n" ..  m["arglists-str"] .. "\n" .. m.doc .. "\n" .. m.file)
  end, false)
end

-- used to suppress output
empty_response = function(m)
end

-- a private/default function for collecting the values that are returned for a given nREPL op.
-- A single nREPL op (e.g Eval) can return multiple responses (e.g Test response), so this
-- function will collect them all and watch for a 'done' status response before sending the
-- output to the user.
buffer_response = function(connection)
  local buffer = {} -- stored alongside the function inside the connection.callbacks variable.
  return function(m)
    log.debug(m) -- always log.debug in an unbuffered way to diagnose errors
    if m.status and contains(m.status, "done") then
      -- TODO how do we know what to return e.g out vs value vs etc?
      log.info(buffer["out"])
      log.info(buffer["value"])
      log.error(buffer["err"])
      connection.callbacks[m.id] = nil -- remove the function from the callbacks map
    elseif m.status and contains(m.status, "state") then
      -- this is what gets used for state updates e.g "changed-namespaces" for now we just log.debug?
    else
      if m.err then
        buffer["err"] = (buffer["err"] or "") .. "\n" .. m.err
      end
      if m.value then
        buffer["value"] = (buffer["value"] or "") .. "\n" .. m.value
      end
      if m.out then
        buffer["out"] = (buffer["out"] or "") .. "\n" .. m.out
      end
    end
  end
end

module.eval = function(connection, code, opts, callback)
  local opts = opts or {}
  network.send(
    connection,
    merge({op = "eval", code = code}, opts),
    callback or buffer_response(connection)
  )
end


-- TODO this code won't work when sessions aren't syned to callbacks properly
module.paths = function(connection)
  local opts = { session = connection.sessions.main }
  network.send(connection, merge({op = "eval", code = clojure.paths_query}, opts), function(m)
    -- TODO we should have a helper/util function to 'close when done' kinda thing
    if m.status and m.status[1] == "done" then
      return
    elseif m["changed-namespaces"] then
      return
    end

    if (m.value == nil) then
      log.error("something is seriously wrong with your nREPL, try a restart? got nil when asking for source paths")
      log.info(vim.inspect(m))
    end
    connection.paths = clojure.user_paths(gsub(m.value, '"(.+)"', "%1"))
  end)
end

module.pwd = function(connection)
  local opts = { session = connection.sessions.main }
  network.send(connection, merge({op = "eval", code = clojure.pwd_query}, opts), function(m)
    if m.status and m.status[1] == "done" then
      return
    elseif m["changed-namespaces"] then
      return
    end
    connection.pwd = gsub(m.value, '"(.+)"', "%1")
  end)
end

module.connect = function(opts)
  local connection = {
    decode = decoder(),
    callbacks = {},
    sessions = {},
    paths = {},
    pwd = "",
    -- TODO really each session should have it's own buffer until { "done" } before printing?
    test_output = {},
    on_error = opts.on_error or function (err)
      log.error(err)
    end,
    on_failure = opts.on_failure or function (err)
      log.error(err)
    end,
    on_success = function ()
      log.info("Connected to Clojure nREPL on port " .. opts.port)
    end
  }

  -- initially brought in because we recieve multiple messages when issue a test run.
  -- the alternative here might be to collect the messages into single ones on done status codes.
  local default_callback = function(m)
    log.debug(m)
    if m.err then
      -- TODO errors passed into with newlines are printed literally \n instead of as real <CR>s
      log.error(m.err)
    elseif m.out then -- e.g stdout from println or response from figwheel cljs-repl startup
      log.info(m.out)
    elseif m.value then
      log.info(m.value)
    end
  end

  local handle_message = function(err, chunk)
    if err then
      connection.on_error(err)
      return
    end

    if not chunk then
      -- we can get empty chunks and no errors if we send empty messages to the nREPL
      log.debug("received empty chunk")
    else
      log.debug("received chunk: " .. chunk)

      local messages = connection.decode(chunk)

      for _, m in ipairs(messages) do
        log.debug("decoded message: " .. vim.inspect(m))

        if m.id then
          local cb = connection.callbacks[m.id]
          log.debug("callback from callbacks map: " .. type(cb))
          if cb then
            cb(m)
          else
            default_callback(m)
          end
        else
          default_callback(m)
        end
      end
    end
  end

  connection["socket"] = network.connect(opts.host, opts.port, vim.schedule_wrap(function (err)
    if err then
      connection.on_failure(err)
    else
      connection.on_success()
      connection.socket.socket:read_start(function (err, chunk)
        handle_message(err, chunk)
      end)
    end
  end)
  )

  return connection
end

module.setup_connection = function(port)
  local host = "127.0.0.1"
  local port = port or clojure.discover_nrepl_port()

  if port then
    local connection = module.connect({ host = host, port = port })
    module.clone(connection, "cljs_eval")
    module.clone(connection, "clj_eval")
    module.clone(connection, "clj_test")
    module.clone(connection, "main")
    module.paths(connection)
    module.pwd(connection)
    return connection
  else
    return nil
  end
end

module.setup = function(config)
  if config.auto_connect then
    return module.setup_connection(port)
  end
end

return module
