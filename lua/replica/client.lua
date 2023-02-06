local bencode = require("replica.bencode")
local clojure = require("replica.clojure")

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
local main_session_id
local eval_session_id
local id = "replica.client"
local partial_chunks = nil

local log = function(message)
    local log_file_path = './replica.log'
    local log_file = io.open(log_file_path, "a")
    io.output(log_file)
    io.write(message.."\n")
    io.close(log_file)
end

clone = function()
  tcp_client:write(encode({op="clone"}))
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
    log(vim.inspect(message))
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
      if eval_session_id == nil then
        eval_session_id = message["new-session"]
        if debug then
          log("new eval session id: "..eval_session_id)
        end
      else
        main_session_id = message["new-session"]
        if debug then
          log("new main session id: "..main_session_id)
        end
      end
    end

    if message["session"] == eval_session_id then
      if debug_eval_only then
        log(vim.inspect(message))
      end
      if message["value"] ~= nil then
        -- TODO really should be writing to a temp buffer also?
        print(message["value"])
      end

      if message["err"] ~= nil then
        -- TODO really should be writing to a temp buffer?
        print(message["err"])
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
    tcp_client, main_session_id, eval_session_id = nil, nil, nil
    log("Client found & disconnected")
  else
    print("Could not find a connection to disconnect!")
  end
end

-- TODO find port based on .nrepl-port?
-- TODO although this is async.. if you do not do anything it takes ages to return the message?
-- I guess this is the nature of async? but it seems to immediately return if I move the cursor.
module.connect = function(host, port)
  if tcp_client then
    module.disconnect()
  end

  local uv = vim.loop
  tcp_client = uv.new_tcp()
  local connection = uv.tcp_connect(tcp_client, host, port, function(err)
    if err then
      print("Could not find an nREPL to connect to on port " .. port)
      log(err)
    end
  end)

  clone() -- for a seperate eval session id
  clone() -- for a new main session id, do this last so it is default for messages we did not initiate
  tcp_client:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      read(chunk)
    else
      tcp_client:shutdown()
      tcp_client:close()
    end
  end)

  -- TODO according to the docs you need this?
  -- however it seems to block the UI and also, it seems to work fine without it?
  -- uv.run()
end

-- TODO we want to fail gracefully if the user tries to use a command without being connected first
-- TODO ideally this is done by wrapping all fns to avoid extra code.. but maybe it's better just to be explicit about
-- this?
-- module.check_connection = function()
--   return tcp_client ~= nil
-- end

module.eval = function(code)
  tcp_client:write(encode({id=id, op="eval", code=code, session=eval_session_id}))
end

module.req = function(ns)
  -- get text from current buffer
  -- get current file
  tcp_client:write(encode({id=id, op="eval", code="(require " .. clojure.namespace() .. ")", session=eval_session_id}))
end

module.describe = function()
  tcp_client:write(encode({id=id, op="describe", session=eval_session_id}))
end

return module
