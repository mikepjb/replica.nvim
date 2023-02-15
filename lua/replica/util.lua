-- for missing 'core' functions

local random = math.random
local insert = table.insert

local module = {}

module.merge = function(a, b)
  for k, v in pairs(b or {}) do a[k] = v end
  return a
end

module.trim = function(s)
  s, _ = string.gsub(s, "%s+$", "")
  return s
end

module.contains = function(t, e)
  for _, v in ipairs(t) do
    if v == e then
      return true
    end
  end
  return false
end

module.split = function(s, p)
  local r = {}
  for i in string.gmatch(s, p) do
    insert(r, i)
  end
  return r
end

-- TODO not used, remove/ using id_gen instead currently
module.uuid = function()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

module.id_gen = function()
  local last_id = 0
  return function()
    last_id = last_id + 1
    return last_id
  end
end

return module
