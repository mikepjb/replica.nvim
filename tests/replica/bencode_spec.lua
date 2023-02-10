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
      assert.are.same(
        {require("replica.bencode").decode("d11:new-session36:e555524a-a2a7-4adb-b529-a77cf49f00dd7:session36:f953ec1d-11bd-40ef-81f8-6d86725c4a456:statusl4:doneee")},
        {{["new-session"]= "e555524a-a2a7-4adb-b529-a77cf49f00dd",
          session= "f953ec1d-11bd-40ef-81f8-6d86725c4a45",
          status= {"done"}}, 120}
      )
    end)
  end)

  describe("decoder", function()
    it("can parse multiple messages contained in a single chunk", function()
      local chunk = "d11:new-session36:95964796-4833-4df3-85d8-366b5314c06c7:session36:a023a4f9-70ee-404f-a0ba-4100fb5646e16:statusl4:doneeed11:new-session36:e555524a-a2a7-4adb-b529-a77cf49f00dd7:session36:f953ec1d-11bd-40ef-81f8-6d86725c4a456:statusl4:doneee"
      local decode = require("replica.bencode").decoder()
      local result = decode(chunk)
      assert.equals(type(result), "table")
      assert.equals(result[1]["new-session"], "95964796-4833-4df3-85d8-366b5314c06c")
      assert.equals(result[2]["new-session"], "e555524a-a2a7-4adb-b529-a77cf49f00dd")
    end)
  end)
end)
