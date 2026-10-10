local M = {}

local icons = require("lazygit-icons.icons")

local function set_highlights()
  for group, fg in pairs(icons.highlights) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end
end

local function part_of(icon, part)
  if part == "icon" then
    return { glyph = icon.glyph }
  end
  if part == "color" then
    return { hl = icon.hl }
  end
  return icon
end

-- What is left of a lazygit icon once `part` of it is excepted.
local function rest_of(icon, part)
  local kept = ({ icon = "color", color = "icon" })[part]
  return icon and kept and part_of(icon, kept) or nil
end

-- Entries are exact file names, or `*.ext` for an extension. A keyed entry names the part it applies to.
local function parse(patterns)
  local parsed = { file = {}, extension = {} }
  for key, value in pairs(patterns or {}) do
    local pattern, part = value, "both"
    if type(key) == "string" then
      pattern, part = key, value
    end
    local ext = pattern:lower():match("^%*%.(.+)$")
    parsed[ext and "extension" or "file"][ext or pattern] = part
  end
  return parsed
end

local function pick(kind, parts)
  if not parts then
    return vim.tbl_extend("force", {}, icons[kind])
  end
  local picked = {}
  for name, part in pairs(parts) do
    picked[name] = icons[kind][name] and part_of(icons[kind][name], part)
  end
  return picked
end

--- Call after mini.icons' own setup(): its config is extended, not replaced.
--- `only` limits the override to the listed file names and `*.ext` extensions; `except` leaves them alone.
---@param opts? { only?: table<integer|string, string>, except?: table<integer|string, string> }
function M.setup(opts)
  opts = opts or {}
  local ok, mini_icons = pcall(require, "mini.icons")
  if not ok then
    vim.notify("[lazygit-icons] requires nvim-mini/mini.icons", vim.log.levels.ERROR)
    return
  end

  local only, except = opts.only and parse(opts.only) or {}, parse(opts.except)
  local file, extension = pick("file", only.file), pick("extension", only.extension)
  for ext, part in pairs(except.extension) do
    extension[ext] = rest_of(extension[ext], part)
  end

  -- lazygit picks by exact file name, then by the lowercased text after the last dot.
  local function lazygit_icon(name)
    return file[name] or extension[(name:match("%.([^.]*)$") or ""):lower()]
  end
  -- mini.icons checks its own file names (built-in and configured) first, so pin those to lazygit's pick.
  for _, name in ipairs(mini_icons.list("file")) do
    file[name] = lazygit_icon(name)
  end
  -- An excepted name can still match an overridden extension, so pin it to what mini.icons shows now.
  for name, part in pairs(except.file) do
    local glyph, hl = mini_icons.get("file", name)
    file[name] = vim.tbl_extend("force", { glyph = glyph, hl = hl }, rest_of(lazygit_icon(name), part) or {})
  end
  mini_icons.setup(vim.tbl_deep_extend("force", mini_icons.config, { file = file, extension = extension }))

  set_highlights()
  -- Colorschemes clear highlights on load, so re-apply after each one.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("lazygit_icons", { clear = true }),
    callback = set_highlights,
  })
end

return M
