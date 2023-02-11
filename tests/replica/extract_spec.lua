describe("sexp extraction", function()
  before_each(function()
    require("replica").setup()
  end)

  it("can take a whole sexp from the end of a given form", function()
    assert.equals(true, true)
    -- TODO "(js/alert \"WHAT\")" doesn't seem to work well, something to do with the forward slash?
    -- however 
    --(comment
    --  (js/alert "whatOK?") <- extract form on just this works!
    --  (prewritten-function)
    --  )
    --
    -- This doesn't work (eval 2nd line)
    -- (println "hello from the replica.nvim test cljs app!")
    -- (print "OHOHOH")
    --
    -- I suspect it may have something to do with the state of the save file.. but this could also be a red herring.
    -- Assume as little as possible here.
  end)
end)
