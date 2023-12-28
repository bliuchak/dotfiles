return {
  {
    "renerocksai/telekasten.nvim",
    lazy = true,
    opts = function()
      local homepath = vim.fn.expand("~/zettelkasten")
      require("telekasten").setup({
        home = homepath,
        dailies = homepath .. "/" .. "calendar",
        subdirs_in_links = false,
      })
    end,
    keys = {
      { "<leader>zd", ":lua require('telekasten').find_daily_notes()<cr>", desc = "Find Daily Notes" },
      { "<leader>zt", ":lua require('telekasten').toggle_todo()<cr>", desc = "Toggle Todo" },
      { "<leader>zb", ":lua require('telekasten').show_backlinks()<cr>", desc = "Show Backlinks" },
    },
  },
}
