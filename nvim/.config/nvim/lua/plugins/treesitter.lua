return {
  "nvim-treesitter/nvim-treesitter",
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
