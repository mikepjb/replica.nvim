local host, port = "127.0.0.1", require("replica.clojure").discover_nrepl_port()
local network = require("replica.network")

describe("network", function()
  before_each(function()
    require("replica").setup({auto_connect = false})
  end)

  after_each(function()
    network.disconnect_all()
  end)

  describe("connections", function()
    it("returns a map of info about a new connection", function()
      local socket_details = network.connect(host, port)
      assert.equals(socket_details.host, "127.0.0.1")
      assert.equals(socket_details.port, port)
      assert.equals(type(socket_details.socket), "userdata")
    end)

    -- TODO we should have 2 registered sessions replica.eval and replica.main when starting.
  end)
end)
