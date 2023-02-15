local uv = vim.loop
local insert = table.insert
local log = require("replica.log")
local bencode = require("replica.bencode")
local util = require("replica.util")

local encode = bencode.encode

local module = {}

module.sockets = {}

new_id = util.id_gen()

module.send = function(connection, message, callback)
  local new_id = new_id()
  connection.callbacks[new_id] = callback -- or nil if not provided
  message["id"] = new_id
  log.debug("send: " .. vim.inspect(message))
  connection.socket.socket:write(encode(message))
end

module.connect = function(host, port, callback)
  local socket = uv.new_tcp()

  socket:connect(host, port, callback)
  local socket_info = {
    socket=socket,
    host=host,
    port=port
  }
  insert(module.sockets, socket_info)
  return socket_info
end

module.disconnect = function(socket)
  if not socket:is_closing() then
    socket:read_stop()
    socket:shutdown()
    socket:close()
  end
end

module.disconnect_all = function()
  for _, s in ipairs(module.sockets) do
    module.disconnect(s.socket)
  end
end

local replica_group = vim.api.nvim_create_augroup("replica", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", {
  command = "lua require(\"replica.network\").disconnect_all()",
  group = replica_group
})

return module
