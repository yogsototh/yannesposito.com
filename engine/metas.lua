-- intermediate store for variables and their values
local variables = {}

--- Function called for each raw block element.
function RawBlock (raw)
  -- Don't do anything unless the block contains *org* markup.
  if raw.format ~= 'org' then return nil end

  -- extract variable name and value
  local name, value = raw.text:match '#%+(%w+):%s*(.+)$'
  if name and value then
    variables[name] = value
  end
end

-- Add the extracted variables to the document's metadata.
function Meta (meta)
  for name, value in pairs(variables) do
    meta[name] = value
  end
  return meta
end
