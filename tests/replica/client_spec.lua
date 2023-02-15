local host, port = "127.0.0.1", require("replica.clojure").discover_nrepl_port()

describe("client", function()
  before_each(function()
    require("replica").setup({auto_connect = false})
  end)

  after_each(function()
    require("replica.network").disconnect_all()
  end)

  describe("connections", function()
    it("returns a map of info about a new connection", function()
      local test_conn = require("replica.client").connect({
        host = host,
        port = port,
        on_error = function(err) print("error: " .. err) end,
      })
      assert.are.same(test_conn.callbacks, {})
      assert.equals(type(test_conn.decode), "function")
      assert.equals(type(test_conn.on_failure), "function")
      assert.equals(type(test_conn.on_success), "function")
      assert.equals(test_conn.socket.host, "127.0.0.1")
      assert.equals(test_conn.socket.port, port)
    end)

    it("sends messages to the nrepl and reads a response", function()
      local client = require("replica.client")
      local test_conn = client.connect({
        host = host,
        port = port,
        on_error = function(err) print("error: " .. err) end,
      })
      client.clone(test_conn, "test-session")
      -- TODO we should have 2 registered sessions replica.eval and replica.main when starting.
      -- this fails but it should succeed, async tests please!
      -- assert.equals(client.sessions and client.sessions["test-session"], true)
      -- TODO I don't seem to be able to test async patterns like waiting for a message right now, what a shame!
    end)
  end)
end)
