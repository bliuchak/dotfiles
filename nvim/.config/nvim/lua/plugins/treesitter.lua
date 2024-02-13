return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    { "luckasRanarison/tree-sitter-hypr" },
    "nvim-treesitter/playground",
  },
  keys = {
    { "<leader>xP", "<cmd>TSPlaygroundToggle<CR>" },
  },
  opts = {
    ensure_installed = {
      "gitignore",
      "go",
      "rust",
      "sql",
      "markdown",
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
