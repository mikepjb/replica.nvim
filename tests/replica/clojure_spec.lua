describe("clojure", function()
  before_each(function()
    require("replica").setup({auto_connect = false})
  end)

  describe("namespaces", function()
    it("derives the namespace based on the current full filepath for a given buffer", function()
      assert.equals(
        require("replica.clojure").namespace({paths={"src/clj"}, pwd="~/src/project"}, "~/src/project/src/clj/project/server/core.clj"),
        "project.server.core"
      )
    end)

    it("correctly converts hypnated namespaces from underscore dirs/files", function()
      assert.equals(
        require("replica.clojure").namespace({paths={"src/clj"}, pwd="~/src/project"}, "~/src/project/src/clj/project/hyphenated_server/hyphenated_core.clj"),
        "project.hyphenated-server.hyphenated-core"
      )
    end)

    it("picks up the last group of identifiable paths to avoid parent directories", function()
      assert.equals(
        require("replica.clojure").namespace({paths={"test"}, pwd="~/src/con"}, "~/src/con/test/con/server/store_test.clj"),
        "con.server.store-test"
      )

    end)

    it("picks up the last group of repeated identifiable paths to avoid parent directories", function()
      assert.equals(
        require("replica.clojure").namespace({paths={"src"}, pwd="~/src/con"}, "~/src/con/src/con/server/store_example.cljc"),
        "con.server.store-example"
      )
    end)

    it("picks up the last group of repeated identifiable paths to avoid parent directories", function()
      local sample_raw_path = "tests/cljs:tests/cljtest:dev:target:/Users/mikepjb/.m2/repository/cider/cider-nrepl/0.28.5/cider-nrepl-0.28.5.jar:/Users/mikepjb/.m2/repository/cider/piggieback/0.5.2/piggieback-0.5.2.jar:/Users/mikepjb/.m2/repository/com/bhauman/figwheel-main/0.2.18/figwheel-main-0.2.18.jar:/Users/mikepjb/.m2/repository/nrepl/nrepl/0.8.3/nrepl-0.8.3.jar:/Users/mikepjb/.m2/repository/org/clojure/clojure/1.11.1/clojure-1.11.1.jar:/Users/mikepjb/.m2/repository/org/clojure/clojurescript/1.11.54/clojurescript-1.11.54.jar:/Users/mikepjb/.m2/repository/reagent/reagent/1.0.0/reagent-1.0.0.jar:/Users/mikepjb/.m2/repository/binaryage/devtools/1.0.5/devtools-1.0.5.jar:/Users/mikepjb/.m2/repository/com/bhauman/certifiable/0.0.7/certifiable-0.0.7.jar"
      assert.are.same(
        require("replica.clojure").user_paths(sample_raw_path),
        {
          "tests/cljs",
          "tests/cljtest",
          "dev",
          "target",
        }
      )
    end)

    it("uses the current full filepath given no arguments", function()
      vim.api.nvim_command("new tests/module/thing")
      assert.equals(
        require("replica.clojure").namespace({paths={"tests"}, pwd="~/src/replica.nvim"}),
        "module.thing"
      )
      vim.api.nvim_command("bdelete")
    end)

    it("defaults to the user namespace if a blank filepath is given (expected for empty buffers)", function()
      assert.equals(
        require("replica.clojure").namespace({paths={"src/clj"}, pwd="~/src/project"}, ""),
        "user"
      )
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
