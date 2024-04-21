return {
  {
    "stevearc/conform.nvim",
    opts = function()
      -- prevent situation when {{ something }} is formatted to { { something } }
      require("conform").formatters.prettier= {
        prepend_args = { "--no-bracket-spacing" },
      }
    end,
  },
}
