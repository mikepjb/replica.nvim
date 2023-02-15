if exists("g:replica_test_mode")
  lua require("replica").setup({auto_connect = false})
else
  lua require("replica").setup()
endif
