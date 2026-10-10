local M = {}

local icons = require("lazygit-icons.icons")

local function set_highlights()
  for group, fg in pairs(icons.highlights) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end
end

-- Entries are exact file names, or `*.ext` for an extension.
local function pick(patterns)
  local file, extension = {}, {}
  for _, pattern in ipairs(patterns) do
    local ext = pattern:lower():match("^%*%.(.+)$")
    if ext then
      extension[ext] = icons.extension[ext]
    else
      file[pattern] = icons.file[pattern]
    end
  end
  return file, extension
end

--- Call after mini.icons' own setup(): its config is extended, not replaced.
---@param opts? { only?: string[] } `only` limits the override to the listed file names and `*.ext` extensions
function M.setup(opts)
  local ok, mini_icons = pcall(require, "mini.icons")
  if not ok then
    vim.notify("[lazygit-icons] requires nvim-mini/mini.icons", vim.log.levels.ERROR)
    return
  end

  local file, extension = vim.tbl_extend("force", {}, icons.file), icons.extension
  if opts and opts.only then
    file, extension = pick(opts.only)
  end

  -- lazygit picks by exact file name, then by the lowercased text after the last dot. mini.icons
  -- checks its own file names (built-in and configured) first, so pin those to lazygit's pick.
  for _, name in ipairs(mini_icons.list("file")) do
    file[name] = file[name] or extension[(name:match("%.([^.]*)$") or ""):lower()]
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
