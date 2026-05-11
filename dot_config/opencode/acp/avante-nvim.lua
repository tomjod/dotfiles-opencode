-- =============================================================
-- ACP Config for Avante.nvim
-- Copy this to your Neovim config (e.g., ~/.config/nvim/lua/plugins/avante.lua)
-- Requires: Avante.nvim installed, opencode in PATH
-- Docs: https://opencode.ai/docs/acp/#avantenvim
-- =============================================================

return {
  "yetone/avante.nvim",
  opts = {
    provider = "acp",
    acp_providers = {
      ["opencode"] = {
        command = "opencode",
        args = { "acp" },
        env = {
          OPENCODE_ENABLE_EXA = "1",
          OPENCODE_EXPERIMENTAL_LSP_TOOL = "true",
        },
      },
    },
  },
}
