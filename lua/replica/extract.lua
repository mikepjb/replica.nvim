-- TODO avoid attempting to load treesitter by default, the user may not have/want this setup.
local ts_utils = require("nvim-treesitter.ts_utils")

local module = {}
local treesitter = {}

treesitter.enabled = function()
  -- TODO again, we want to know if treesitter is installed otherwise this won't work.
  return true
end

-- form returns an sexp as a string to send for evaluation (by default the sexp under cursor)
module.form = function() -- TODO take opts?
  if treesitter.enabled() then
    -- TODO currently requires you to be hovering an sexp, this can be improved
    -- Range returns 4 integers, start_row, start_column, end_row, end_column
    local srow, scol, erow, ecol = ts_utils.get_node_at_cursor():range()
    local sexp = ""
    for _, line in ipairs(vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})) do
      sexp = sexp .. line .. "\n"
    end
    return sexp
  end
end

return module
