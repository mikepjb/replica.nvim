local bencode = require("replica.bencode")

local decode, encode = bencode.decode, bencode.encode
local insert, concat = table.insert, table.concat

local module = {}

-- Learning notes: if you have a uv__check_before_write error, make sure you aren't trying to sent tables over the
-- wire. This can happen if you aren't bencoding messages first.

local tcp_client -- TCP client for sending messages
local session_id
local id = "replica.client"
local partial_chunks = nil

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
  print(vim.inspect(message))

  if message == nil then
    -- in this case, the chunk is not parseable which probably means we have part of a big message.
    if partial_chunks == nil then
      partial_chunks = {}
    end
    insert(partial_chunks, chunk)
  else
    partial_chunks = {} -- reset as we have a full parsed message
    if message["new-session"] ~= nil then
      session_id = message["new-session"]
      print("new session id: "..session_id)
    end
  end
end

-- TODO find port based on .nrepl-port?
-- TODO although this is async.. if you do not do anything it takes ages to return the message?
-- I guess this is the nature of async? but it seems to immediately return if I move the cursor.
module.connect = function(host, port)
  local uv = vim.loop
  tcp_client = uv.new_tcp()
  local connection = uv.tcp_connect(tcp_client, host, port, function(err)
    assert(not err, err)
  end)

  clone()
  tcp_client:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      read(chunk)
    else
      client:shutdown()
      client:close()
    end
  end)

  uv.run()
end

module.eval = function(ns, code)
  tcp_client:write(encode({id=id, ns=ns, op="eval", code=code, session=session_id}))
end

return module
