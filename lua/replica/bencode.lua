local module = {}

-- N.B message can be bytes, string, integer, array, object/map containing any combination of the rest!
module.type_encoders = {
  number = function(n)
    return "i"..n.."e"
  end,
  string = function(s)
    return string.len(s) .. ":" .. s
  end,
  -- Arrays and Dictionaries are both Tables in Lua We assume number indexed Tables are in fact Arrays and are encoded
  -- as such.
  table = function(t)
    if t[1] == nil then -- check if this is a dictionary
      local out_dict = "d"
      for k, v in pairs(t) do
        out_dict = out_dict .. module.encode(k) .. module.encode(v) 
      end
      return out_dict .. "e"
      -- return "dict"
    else
      local out_list = "l"
      for _, v in pairs(t) do
        out_list = out_list .. module.encode(v) 
      end
      return out_list .. "e"
    end
  end,
}

module.encode = function(message)

  local type_encoder = module.type_encoders[type(message)]

  if type(type_encoder) == 'function' then
    return module.type_encoders[type(message)](message)
  else
    return "not sure what to do with message type: "..type(message)
  end
  -- return 'yes.'
end

return module
