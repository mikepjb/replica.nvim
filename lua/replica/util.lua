-- for missing 'core' functions

local module = {}

module.merge = function(a, b)
  for k, v in pairs(b) do a[k] = v end
  return a
end

return module
