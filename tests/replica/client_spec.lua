local host, port = "127.0.0.1", require("replica.clojure").discover_nrepl_port()

describe("client", function()
  before_each(function()
    require("replica").setup()
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
      assert.are.same(test_conn.queue, {})
      assert.equals(type(test_conn.decode), "function")
      assert.equals(type(test_conn.on_failure), "function")
      assert.equals(type(test_conn.on_success), "function")
      assert.equals(test_conn.socket.host, "127.0.0.1")
      assert.equals(test_conn.socket.port, port)
    end)

    -- TODO we should have 2 registered sessions replica.eval and replica.main when starting.
  end)
end)
