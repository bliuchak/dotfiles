return {
  {
    "renerocksai/telekasten.nvim",
    lazy = true,
    opts = function()
      local homepath = vim.fn.expand("~/zettelkasten")
      require("telekasten").setup({
        home = homepath,
        dailies = homepath .. "/calendar",
        weeklies = homepath .. "/calendar",
        subdirs_in_links = false,
        auto_set_filetype = false,
      })
    end,
    keys = {
      { "<leader>ze", ":lua require('telekasten').panel()<cr>", desc = "Telekasten Panel" },
      { "<leader>zd", ":lua require('telekasten').find_daily_notes()<cr>", desc = "Find Daily Notes" },
      { "<leader>zt", ":lua require('telekasten').toggle_todo()<cr>", desc = "Toggle Todo" },
      { "<leader>zb", ":lua require('telekasten').show_backlinks()<cr>", desc = "Show Backlinks" },
      { "<leader>zg", ":lua require('telekasten').show_tags()<cr>", desc = "Show Tags" },
      { "<leader>zn", ":lua require('telekasten').new_note()<cr>", desc = "New Note" },
    },
  },
}
