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
      -- Also, it's order is non-deterministic.
      local example_dictionary = {}
      example_dictionary["code"] = "(+ 40 2)"
      example_dictionary["session"] = "sample"

      local expected_encoding = "d7:session6:sample4:code8:(+ 40 2)e"
      local expected_alt_order_encoding = "d4:code8:(+ 40 2)7:session6:samplee"
      local encoded_dictionary = require("replica.bencode").encode(example_dictionary)
      assert.is_true(
        encoded_dictionary == expected_encoding or encoded_dictionary == expected_alt_order_encoding
      )
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

  describe("decoding messages into bencode format", function()
    it("refuses to decode empty messages", function()
      assert.are.same({require("replica.bencode").decode()}, {nil, "no data", nil})
    end)

    it("detects reading beyond message length", function()
      assert.are.same({require("replica.bencode").decode("a", 3)}, {nil, "truncation error", nil})
    end)

    it("detects unknown types", function()
      assert.are.same(
        {require("replica.bencode").decode("asfsdafasdf", 3)},
        {nil, "unknown type", "asfsdafasdf"}
      )
    end)

    -- it("decodes a string", function()
    --   assert.equals(require("replica.bencode").decode("5:clone"), "clone")
    -- end)

    -- it("decodes a string, returning the remaining message", function()
    --   assert.are.same(
    --     require("replica.bencode").decode_int("5:clone3:eye"),
    --     { value="clone", remaining_message="3:eye" }
    --   )
    -- end)

    -- it("decodes a list with a single element", function()
    --   assert.equals(require("replica.bencode").decode("l5:clonee"), {"clone"})
    -- end)

    -- it("decodes a list with two elements", function()
    --   assert.equals(require("replica.bencode").decode("l5:clone3:eyee"), {"clone", "eye"})
    -- end)

    -- it("decodes a simple single key/pair dictionary", function()
    --   assert.equals(require("replica.bencode").decode("d2op:5clonee"), {op="clone"})
    -- end)
  end)
end)
