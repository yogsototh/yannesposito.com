-- img-to-webp.lua
function Image(el)
  local fileext = el.src:match("%.[^%.]+$");
  -- DEBUG -- print("LUA IMG: ", fileext);
  if ( fileext == ".jpg" or fileext == ".png" or fileext == ".jpeg" ) then
    el.src = el.src .. ".webp"
  end
  return el
end
