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

module.open_example = function()
  local uv = vim.loop
  local client = uv.new_tcp()
  local connection = uv.tcp_connect(client, "127.0.0.1", 52216, function (err)
    assert(not err, err)
  end)

  client:write("d2:op5:clonee")
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
end

module.setup = function()
  -- local cmd = nvim_create_user_command

  -- cmd("Connect" 'echo "Hello world!"', {})
  -- vim.api.nvim_create_user_command("Connect", 'echo "Hello world!"', {})
  vim.api.nvim_create_user_command("Connect", module.open_example, {})
  return
end

return module
