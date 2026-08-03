-- links-to-html.lua
function Link(el)
  -- pandoc's org reader reads an absolute target such as [[/posts/x.html]] as a
  -- local path and prefixes it with file://, which breaks the link once served.
  -- Relative targets and explicit [[file:rel/path]] come out of the reader
  -- without the scheme, so anchoring on ^ only undoes what pandoc added.
  el.target = string.gsub(el.target, "^file://", "")
  -- this if is necessary to not match .org domains, but only .org files.
  if (not (string.match(el.target, "https?://"))) then
     el.target = string.gsub(string.gsub(el.target, "%.org", ".html"), "%.html::", ".html#" )
  end
  return el
end
