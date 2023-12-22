return {
  'nvimtools/none-ls.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'jay-babu/mason-null-ls.nvim',
  },
  opts = function()
    local null_ls = require 'null-ls'
    local formatting = null_ls.builtins.formatting
    local diagnostics = null_ls.builtins.diagnostics
    local code_actions = null_ls.builtins.code_actions
    -- local completion = null_ls.builtins.completion
    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
    return {
      sources = {
        formatting.gofumpt,
        formatting.goimports_reviser,
        formatting.markdownlint,
        formatting.stylua,
        formatting.prettier.with {
          filetypes = { 'yaml', 'json' },
        },
        formatting.terraform_fmt,
        diagnostics.checkmake,
        diagnostics.commitlint,
        diagnostics.hadolint,
        diagnostics.jsonlint,
        diagnostics.luacheck,
        diagnostics.shellcheck,
        diagnostics.markdownlint,
        diagnostics.yamllint,
        diagnostics.tfsec,
        code_actions.gomodifytags,
      },
      on_attach = function(client, bufnr)
        if client.supports_method 'textDocument/formatting' then
          vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format {
                async = false,
                filter = function()
                  return client.name == 'null-ls'
                end,
              }
            end,
          })
        end
      end,
    }
  end,
}
