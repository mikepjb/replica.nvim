-- for missing 'core' functions

local random = math.random

local module = {}

module.merge = function(a, b)
  for k, v in pairs(b) do a[k] = v end
  return a
end

module.trim = function(s)
  s, _ = string.gsub(s, "%s+$", "")
  return s
end

module.uuid = function()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

return module
