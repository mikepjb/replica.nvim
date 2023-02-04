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

    it("encodes an array of strings", function()
      -- In Lua, an array is a table of integer index values e.g 1 => "thing", 2 => "next'
      -- Oh yeah, also it's 1-indexed
      local example_array = {"this", "is", "an", "array"}
      local expected_encoding = "l4:this2:is2:an5:arraye"
      assert.equals(require("replica.bencode").encode(example_array), expected_encoding)
    end)

    it("encodes an dictionary of strings", function()
      -- In Lua, an array is a table of integer index values e.g 1 => "thing", 2 => "next'
      -- Oh yeah, also it's 1-indexed
      local example_dictionary = {}
      example_dictionary["code"] = "(+ 40 2)"
      example_dictionary["session"] = "sample"

      local expected_encoding = "d7:session6:sample4:code8:(+ 40 2)e"
      assert.equals(require("replica.bencode").encode(example_dictionary), expected_encoding)
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
