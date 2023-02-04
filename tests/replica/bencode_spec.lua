describe("replica", function()
  before_each(function()
    require("replica").setup()
  end)

  describe("encoding messages into bencode format", function()
    -- not necessary? I think clojure nREPL only deals with strings/lists/maps
    it("encodes a single integer", function()
      assert.equals(require("replica.bencode").encode(5), "i5e")
    end)

    it("encodes a single string", function()
      assert.equals(require("replica.bencode").encode("Hello, nREPL!"), "13:Hello, nREPL!")
    end)
  end)

  describe("errors when given an unknown message type", function()
    it("nil is not encodable/useful as a message", function()
      assert.equals(
        require("replica.bencode").encode(nil),
        "not sure what to do with message type: nil"
      )
    end)
  end)
end)
