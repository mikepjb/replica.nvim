
describe("replica", function()
  before_each(function()
    require("replica").setup()
  end)

  describe("encoding messages into bencode format", function()
    it("encodes a single integer", function()
      assert.equals(require("replica.bencode").encode(5), "yes.")
    end)
  end)
end)
