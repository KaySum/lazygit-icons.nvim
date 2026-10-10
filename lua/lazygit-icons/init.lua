local M = {}

local icons = require("lazygit-icons.icons")

local function set_highlights()
  for group, fg in pairs(icons.highlights) do
    vim.api.nvim_set_hl(0, group, { fg = fg })
  end
end

-- lazygit picks by exact file name, then by the lowercased text after the last dot.
local function lazygit_icon(name)
  return icons.file[name] or icons.extension[(name:match("%.([^.]*)$") or ""):lower()]
end

--- Call after mini.icons' own setup(): its config is extended, not replaced.
function M.setup()
  local ok, mini_icons = pcall(require, "mini.icons")
  if not ok then
    vim.notify("[lazygit-icons] requires nvim-mini/mini.icons", vim.log.levels.ERROR)
    return
  end

  -- mini.icons checks file names (built-in and configured) before extensions; lazygit doesn't
  -- know those names and would pick by extension, so pin them to that icon.
  local file = vim.tbl_extend("force", {}, icons.file)
  for _, name in ipairs(mini_icons.list("file")) do
    file[name] = lazygit_icon(name)
  end
  mini_icons.setup(vim.tbl_deep_extend("force", mini_icons.config, { file = file, extension = icons.extension }))

  set_highlights()
  -- Colorschemes clear highlights on load, so re-apply after each one.
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("lazygit_icons", { clear = true }),
    callback = set_highlights,
  })
end

return M
