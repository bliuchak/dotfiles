return {
  'renerocksai/telekasten.nvim',
  lazy = true,
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    local telekasten_home = vim.fn.expand(os.getenv 'TELEKASTEN_HOME')

    require('telekasten').setup {
      home = telekasten_home,
      dailies = telekasten_home .. '/' .. 'calendar',
      command_palette_theme = 'window',
      auto_set_filetype = false,
    }
  end,
  keys = {
    { '<leader>t', ":lua require('telekasten').panel()<CR>", desc = 'Telekasten' },
    { '<leader>td', ":lua require('telekasten').find_daily_notes()<CR>", desc = 'Find daily notes' },
    { '<leader>tT', ":lua require('telekasten').goto_today()<CR>", desc = 'Go to today' },
    { '<leader>tn', ":lua require('telekasten').new_note()<CR>", desc = 'New note' },
    { '<leader>tt', ":lua require('telekasten').toggle_todo()<CR>", desc = 'Toggle todo' },
  },
}
