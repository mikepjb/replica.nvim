local bencode = require("replica.bencode")

local module = {}

-- Learning for nREPL
--
-- neovim has a stdlib assigned as the 'vim' module
--
-- The loop exposes all the features of the Nvim event-loop, of which there are some TCP commands
-- tcp_connect
-- tcp_open
-- etc.
-- https://neovim.io/doc/user/luvref.html#luv-intro
-- lua print(vim.inspect(vim.loop))

module.example = function()
  local uv = vim.loop
  local server = uv.new_tcp()
  server:bind("127.0.0.1", 52200)
  server:listen(128, function (err)
    assert(not err, err)
    local client = uv.new_tcp()
    server:accept(client)
    client:read_start(function (err, chunk)
      assert(not err, err)
      if chunk then
        print("got message back")
        print(chunk)
      else
        client:shutdown()
        client:close()
      end
    end)

    -- client:write("d2:op5:clonee")
  end)
  print("TCP server started with initial clone message")
  uv.run()
end

-- TODO having a module.client won't work for multiple nREPL connections, maybe we will need a collection of
-- connections for clj and cljs to connect at the same time?
-- XXX answer: I think we have a single TCP connection and grab 2 sessions?
module.open_example = function()
  local uv = vim.loop
  -- local client = uv.new_tcp()
  module.client = uv.new_tcp()
  local connection = uv.tcp_connect(module.client, "127.0.0.1", 52216, function (err)
    assert(not err, err)
  end)

  module.client:write(bencode.encode({op="clone"}))
  module.client:read_start(function (err, chunk)
    assert(not err, err)

    if chunk then
      print("got message back")
      print(chunk)
      -- this will always try to get a session id
      -- assumes session-id will always be 36 characters long
      module.id = vim.split(chunk, ":")[3]:sub(0, 36)
      print(module.id)
    else
      module.client:shutdown()
      module.client:close()
    end
  end)
end

module.message = function(id, session, code)
  local msg = string.format("d4:code%s:%s2:id%s:%s2:op4:eval7:session%s:%se", string.len(code), code, string.len(id), id, string.len(session), session)
  print(msg)
  module.client:write(msg)
end

module.clone = function()
  module.client:write("d2:op5:clonee")
end

module.setup = function()
  -- local cmd = nvim_create_user_command

  -- cmd("Connect" 'echo "Hello world!"', {})
  -- vim.api.nvim_create_user_command("Connect", 'echo "Hello world!"', {})
  vim.api.nvim_create_user_command("Connect", module.open_example, {})
  vim.api.nvim_create_user_command("Clone", module.clone, {})
  vim.api.nvim_create_user_command("Message", function () module.message("test", module.id, "(+ 40 2)") end, {})
  return
end

return module
