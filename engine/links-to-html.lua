-- links-to-html.lua
function Link(el)
  -- this if is necessary to not match .org domains, but only .org files.
  if (not (string.match(el.target, "https?://"))) then
     el.target = string.gsub(string.gsub(el.target, "%.org", ".html"), "%.html::", ".html#" )
  end
  return el
end
