local module = {}

-- N.B message can be bytes, string, integer, array, object/map containing any combination of the rest!
module.type_encoders = {
  number = function()
    return 'i am a number'
  end,
}

module.encode = function(message)

  local type_encoder = module.type_encoders[type(message)]

  if type(type_encoder) == 'function' then
    return module.type_encoders[type(message)]()
  else
    return "not sure what to do with message type: "..type(message)
  end
  -- return 'yes.'
end

return module
