-- Lua filter to handle date-range spans in headers for LaTeX
-- Creates a two-column layout: title on left (wrapping), date on right

-- Escape special LaTeX characters
local function escape_latex(s)
  s = s:gsub("&", "\\&")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("%$", "\\$")
  s = s:gsub("#", "\\#")
  s = s:gsub("_", "\\_")
  s = s:gsub("{", "\\{")
  s = s:gsub("}", "\\}")
  s = s:gsub("~", "\\textasciitilde{}")
  s = s:gsub("%^", "\\textasciicircum{}")
  return s
end

local function process_header(el)
  if not FORMAT:match("latex") then
    return el
  end

  -- Look for date-range span in header content
  local date_text = nil
  local title_content = {}

  for i, item in ipairs(el.content) do
    if item.t == "Span" and item.classes:includes("date-range") then
      date_text = pandoc.utils.stringify(item.content)
    else
      table.insert(title_content, item)
    end
  end

  -- If no date-range found, return unchanged
  if not date_text then
    return el
  end

  -- Remove trailing space from title content
  while #title_content > 0 and title_content[#title_content].t == "Space" do
    table.remove(title_content)
  end

  -- Convert title content to LaTeX string manually
  local title_parts = {}
  for _, item in ipairs(title_content) do
    if item.t == "Str" then
      table.insert(title_parts, escape_latex(item.text))
    elseif item.t == "Space" then
      table.insert(title_parts, " ")
    elseif item.t == "Span" and item.classes:includes("role-detail") then
      -- Wrap role-detail in mbox to prevent line breaks
      local detail_text = escape_latex(pandoc.utils.stringify(item.content))
      table.insert(title_parts, "\\mbox{" .. detail_text .. "}")
    elseif item.t == "Link" then
      -- Handle links
      local link_text = escape_latex(pandoc.utils.stringify(item.content))
      local url = item.target
      table.insert(title_parts, "\\href{" .. url .. "}{" .. link_text .. "}")
    elseif item.t == "RawInline" then
      -- Skip HTML raw inlines (like SVG icons) in LaTeX
      if item.format ~= "html" then
        table.insert(title_parts, item.text)
      end
    end
  end
  local title_str = table.concat(title_parts, "")

  -- Normalize en dash with 0.5em spacing
  -- Handle various spacing patterns around en dash
  title_str = title_str:gsub(" – ", "\\hspace{0.5em}\\textendash\\hspace{0.5em}")
  title_str = title_str:gsub("\194\160– ", "\\hspace{0.5em}\\textendash\\hspace{0.5em}")  -- nbsp (UTF-8: C2 A0) + en dash + space
  title_str = title_str:gsub(" –", "\\hspace{0.5em}\\textendash\\hspace{0.5em}")
  title_str = title_str:gsub("– ", "\\hspace{0.5em}\\textendash\\hspace{0.5em}")
  title_str = title_str:gsub("–", "\\hspace{0.5em}\\textendash\\hspace{0.5em}")
  -- Also handle em dash if still present
  title_str = title_str:gsub("—", "\\hspace{0.5em}\\textendash\\hspace{0.5em}")

  -- Prevent orphans by adding non-breaking spaces between last few words
  -- Replace last 2 regular spaces with non-breaking spaces
  local space_count = 0
  title_str = title_str:gsub(" ([^ ]+)$", function(word)
    return "~" .. word
  end)
  title_str = title_str:gsub(" ([^ ]+~[^ ]+)$", function(words)
    return "~" .. words
  end)

  -- Handle "part-time" in date: move to second line in parentheses
  local date_main = date_text
  local date_extra = nil
  if date_text:match("%(part%-time%)") then
    date_main = date_text:gsub("%s*%(part%-time%)", "")
    date_extra = "(part-time)"
  end

  local date_latex
  if date_extra then
    date_latex = string.format("{\\sflight %s}\\\\{\\sflight %s}", date_main, date_extra)
  else
    date_latex = string.format("{\\sflight %s}", date_main)
  end

  local latex_code = string.format(
    "\\parbox[b]{0.72\\linewidth}{\\raggedright\\widowpenalty=10000\\clubpenalty=10000 %s}\\hfill\\parbox[b]{0.25\\linewidth}{\\raggedleft %s}",
    title_str,
    date_latex
  )

  el.content = {pandoc.RawInline("latex", latex_code)}
  return el
end

-- Return filter with explicit traversal order
-- Process headers first (before spans get converted)
return {
  {Header = process_header}
}
