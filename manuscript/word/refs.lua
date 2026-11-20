-- Pandoc Lua filter for `make word`: replaces each \ref{label} by the number
-- LaTeX gives that label (e.g. "3", "S5"), read from the .aux files that
-- build_word.sh writes to $GAMDID_AUX. References to the manuscript's own
-- figures stay links; references to the supplemental documents become text.

local labels = {}   -- label -> number
local internal = {} -- labels defined in the manuscript itself

local function read_aux(path, own)
  local f = io.open(path)
  if not f then return end
  for line in f:lines() do
    local lab, num = line:match('^\\newlabel{([^}]*)}{{([^}]*)}')
    if lab and labels[lab] == nil then
      labels[lab] = num
      internal[lab] = own
    end
  end
  f:close()
end

local dir = os.getenv('GAMDID_AUX') or '.'
read_aux(dir .. '/gamdid_manuscript.aux', true)
for _, p in ipairs({ 'figures', 'tables', 'methods' }) do
  read_aux(dir .. '/gamdid_supplemental_' .. p .. '.aux', false)
end

function Link(el)
  local lab = el.attributes['reference']
  if lab == nil then return nil end
  local num = labels[lab]
  if num == nil then
    io.stderr:write('make word: unresolved reference ' .. lab .. '\n')
    return nil
  end
  if internal[lab] then
    el.content = { pandoc.Str(num) }
    return el
  end
  return pandoc.Str(num)
end
