--[[
change-badge.lua: render ::: {.change} blocks as "Changed in <version>" badges.

  ::: {.change #C1226-04 type="data" from="0926" anchor="model-development"}
  One or two sentences: what changed and the effect on results.
  :::

  #C1226-04  change ID (must match the Annex F entry)
  type       method | data   (clarifications and editorial fixes get no badge)
  from       code of the previous version, e.g. 0926
  anchor     section ID in the previous version (defaults to the enclosing
             section's ID, which is stable because IDs are explicit)

HTML: expandable pill with the note and a link to the same section in the
previous version. Typst/PDF: a marked note. Other formats: the note as-is.
]]

local current = "?"

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function typst_esc(s)
  return (s:gsub("([#%[%]\\])", "\\%1"))
end

local function badge(div, section_id)
  local id = div.identifier
  local kind = (div.attributes["type"] or "change"):lower()
  local from = div.attributes["from"] or ""
  local anchor = div.attributes["anchor"] or section_id or ""
  local kind_label = kind:sub(1, 1):upper() .. kind:sub(2)

  if quarto.doc.is_format("html") then
    local prev = ""
    if from ~= "" then
      local href = "/ai-emissions/" .. from .. "/" .. (anchor ~= "" and ("#" .. anchor) or "")
      prev = '<a class="saig-change-prev" href="' .. esc(href) .. '">View this section in CAIEC-'
        .. esc(from) .. ' →</a>'
    end
    local open = pandoc.RawBlock("html",
      '<div class="saig-change saig-change-' .. esc(kind) .. '"' ..
      (id ~= "" and (' id="' .. esc(id) .. '"') or "") .. '><details>' ..
      '<summary><span class="saig-change-pill">Changed in ' .. esc(current) .. '</span>' ..
      '<span class="saig-change-meta">' .. esc(id) .. ' · ' .. esc(kind_label) .. '</span></summary>' ..
      '<div class="saig-change-body">')
    local close = pandoc.RawBlock("html", prev .. '</div></details></div>')
    local out = pandoc.List({ open })
    out:extend(div.content)
    out:insert(close)
    return out
  elseif quarto.doc.is_format("typst") then
    local label = "CHANGED IN " .. current .. " · " .. id .. " · " .. kind_label:upper()
    if from ~= "" then
      label = label .. " · PREVIOUSLY CAIEC-" .. from
    end
    local open = pandoc.RawBlock("typst",
      '#block(width: 100%, inset: (left: 9pt, top: 5pt, bottom: 5pt), stroke: (left: 2pt + rgb("#B8663B")), fill: rgb("#F5F1E9"))[' ..
      '#text(font: "DM Mono", size: 7.5pt, fill: rgb("#B8663B"))[' .. typst_esc(label) .. '] \\\n')
    local out = pandoc.List({ open })
    out:extend(div.content)
    out:insert(pandoc.RawBlock("typst", "]"))
    return out
  end
  return div.content
end

function Pandoc(doc)
  local v = doc.meta.report and doc.meta.report.version
  if v then
    current = pandoc.utils.stringify(v):gsub("^CAIEC%-", "")
  end

  -- Walk top-level blocks, remembering the most recent heading ID so that a
  -- badge without an explicit anchor links to its own section.
  local section_id = nil
  local function walk(blocks)
    local out = pandoc.List()
    for _, b in ipairs(blocks) do
      if b.t == "Header" then
        section_id = b.identifier
        out:insert(b)
      elseif b.t == "Div" and b.classes:includes("change") then
        out:extend(badge(b, section_id))
      elseif b.t == "Div" then
        b.content = walk(b.content)
        out:insert(b)
      else
        out:insert(b)
      end
    end
    return out
  end
  doc.blocks = walk(doc.blocks)
  return doc
end
