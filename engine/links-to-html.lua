-- links-to-html.lua
function Link(el)
  el.target = string.gsub(string.gsub(el.target, "%.org", ".html"), "%.html::", ".html#" )
  return el
end
