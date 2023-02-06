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

    it("avoids parsing strings without length", function()
      assert.are.same(
        {require("replica.bencode").type_decoders["string"](":clone")},
        {nil, "no length detected", nil}
      )
    end)

    it("detects integers", function()
      assert.are.same(
        {require("replica.bencode").decode("i567e")},
        {567, 6}
      )
    end)

    it("detects strings", function()
      assert.are.same(
        {require("replica.bencode").decode("5:clone")},
        {"clone", 8}
      )
    end)

    it("detects incomplete strings", function()
      assert.are.same(
        {require("replica.bencode").decode("7:clone")},
        {nil, "truncated string at end of input", "clone"}
      )
    end)

    it("decodes a simple single key/pair dictionary", function()
      assert.are.same(
        {require("replica.bencode").decode("d2:op5:clonee")},
        {{op="clone"}, 14}
      )
    end)

    it("decodes a multiple key/pair dictionary", function()
      assert.are.same(
        {require("replica.bencode").decode("d2:op5:clone4:code8:(+ 40 2)e")},
        {{op="clone", code="(+ 40 2)"}, 30}
      )
    end)

    it("decodes a list", function()
      assert.are.same(
        {require("replica.bencode").decode("l2:op5:clone4:code8:(+ 40 2)e")},
        {{"op", "clone", "code", "(+ 40 2)"}, 30}
      )
    end)

    it("decodes a list, inside a dictionary", function()
      assert.are.same(
        {require("replica.bencode").decode("l2:op5:clone4:codel8:(+ 40 2)11:second codeee")},
        {{"op", "clone", "code", {"(+ 40 2)", "second code"}}, 46}
      )
    end)
  end)
end)
