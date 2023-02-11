describe("clojure", function()
  before_each(function()
    require("replica").setup()
  end)

  describe("namespaces", function()
    it("derives the namespace based on the current full filepath for a given buffer", function()
      assert.equals(
        require("replica.clojure").namespace("~/src/project/src/clj/project/server/core.clj"),
        "project.server.core"
      )
    end)

    it("correctly converts hypnated namespaces from underscore dirs/files", function()
      assert.equals(
        require("replica.clojure").namespace("~/src/project/src/clj/project/hyphenated_server/hyphenated_core.clj"),
        "project.hyphenated-server.hyphenated-core"
      )
    end)

    it("uses the current full filepath given no arguments", function()
      vim.api.nvim_command("new thing")
      assert.equals(
        require("replica.clojure").namespace(),
        "replica.nvim.thing"
      )
      vim.api.nvim_command("bdelete")
    end)
  end)

  describe("identifying clojurescript", function()
    it("figures out clojurescript files based on extension", function()
      assert.equals(
        require("replica.clojure").is_cljs("this_thing.cljs"),
        true
      )
      assert.equals(
        require("replica.clojure").is_cljs("this_thing.cljx"),
        false
      )
    end)
  end)
end)
