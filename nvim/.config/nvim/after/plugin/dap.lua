-- stolen from https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/after/plugin/dap.lua
local has_dap, dap = pcall(require, "dap")
if not has_dap then
  return
end

vim.fn.sign_define("DapBreakpoint", { text = "ß", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "ü", texthl = "", linehl = "", numhl = "" })
-- Setup cool Among Us as avatar
vim.fn.sign_define("DapStopped", { text = "ඞ", texthl = "Error" })

require("nvim-dap-virtual-text").setup({
  enabled = true,

  -- DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, DapVirtualTextForceRefresh
  enabled_commands = false,

  -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
  highlight_changed_variables = true,
  highlight_new_as_changed = true,

  -- prefix virtual text with comment string
  commented = false,

  show_stop_reason = true,

  -- experimental features:
  virt_text_pos = "eol", -- position of virtual text, see `:h nvim_buf_set_extmark()`
  all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
})

--  https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#go-using-delve-directly
dap.adapters.go = function(callback, _)
  local stdout = vim.loop.new_pipe(false)
  local handle, pid_or_err
  local port = 38697

  handle, pid_or_err = vim.loop.spawn("dlv", {
    stdio = { nil, stdout },
    args = { "dap", "-l", "127.0.0.1:" .. port },
    detached = true,
  }, function(code)
    stdout:close()
    handle:close()

    print("[delve] Exit Code:", code)
  end)

  assert(handle, "Error running dlv: " .. tostring(pid_or_err))

  stdout:read_start(function(err, chunk)
    assert(not err, err)

    if chunk then
      vim.schedule(function()
        require("dap.repl").append(chunk)
        print("[delve]", chunk)
      end)
    end
  end)

  -- Wait for delve to start
  vim.defer_fn(function()
    callback({ type = "server", host = "127.0.0.1", port = port })
  end, 100)
end

-- FIXME: it's not working for some reasons
-- dap.configurations.go = {
--   {
--     type = "go",
--     name = "Debug (from vscode-go)",
--     request = "launch",
--     showLog = false,
--     program = "${file}",
--     dlvToolPath = vim.fn.exepath("dlv"), -- Adjust to where delve is installed
--   },
--   {
--     type = "go",
--     name = "Debug (No File)",
--     request = "launch",
--     program = "",
--   },
--   {
--     type = "go",
--     name = "Debug",
--     request = "launch",
--     program = "${file}",
--     showLog = true,
--     -- console = "externalTerminal",
--     -- dlvToolPath = vim.fn.exepath "dlv",
--   },
--   {
--     name = "Test Current File",
--     type = "go",
--     request = "launch",
--     showLog = true,
--     mode = "test",
--     program = ".",
--     dlvToolPath = vim.fn.exepath("dlv"),
--   },
--   {
--     type = "go",
--     name = "Run lsif-clang indexer",
--     request = "launch",
--     showLog = true,
--     program = ".",
--     args = {
--       "--indexer",
--       "lsif-clang compile_commands.json",
--       "--dir",
--       vim.fn.expand("~/sourcegraph/lsif-clang/functionaltest"),
--       "--debug",
--     },
--     dlvToolPath = vim.fn.exepath("dlv"),
--   },
--   {
--     type = "go",
--     name = "Run lsif-go-imports in smol_go",
--     request = "launch",
--     showLog = true,
--     program = "./cmd/lsif-go",
--     args = {
--       "--project-root=/home/tjdevries/sourcegraph/smol_go/",
--       "--repository-root=/home/tjdevries/sourcegraph/smol_go/",
--       "--module-root=/home/tjdevries/sourcegraph/smol_go/",
--       "--repository-remote=github.com/tjdevries/smol_go",
--       "--no-animation",
--     },
--     dlvToolPath = vim.fn.exepath("dlv"),
--   },
--   {
--     type = "go",
--     name = "Run lsif-go-imports in sourcegraph",
--     request = "launch",
--     showLog = true,
--     program = "./cmd/lsif-go",
--     args = {
--       "--project-root=/home/tjdevries/sourcegraph/sourcegraph.git/main",
--       "--repository-root=/home/tjdevries/sourcegraph/sourcegraph.git/main",
--       "--module-root=/home/tjdevries/sourcegraph/sourcegraph.git/main",
--       "--no-animation",
--     },
--     dlvToolPath = vim.fn.exepath("dlv"),
--   },
-- }

--
local map = function(lhs, rhs, desc)
  if desc then
    desc = "[DAP] " .. desc
  end

  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

-- map("<leader><F5>", function()
--   if vim.bo.filetype ~= "rust" then
--     vim.notify("This wasn't rust. I don't know what to do")
--     return
--   end
--
--   -- R("tj.dap").select_rust_runnable()
-- end)

map("<F1>", require("dap").step_back, "step_back")
map("<F2>", require("dap").step_into, "step_into")
map("<F3>", require("dap").step_over, "step_over")
map("<F4>", require("dap").step_out, "step_out")
map("<F5>", require("dap").continue, "continue")

-- TODO:
-- disconnect vs. terminate

map("<leader>dr", require("dap").repl.open)

map("<leader>db", require("dap").toggle_breakpoint)
map("<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input("[DAP] Condition > "))
end)

map("<leader>de", require("dapui").eval)
map("<leader>dE", function()
  require("dapui").eval(vim.fn.input("[DAP] Expression > "))
end)

-- You can set trigger characters OR it will default to '.'
-- You can also trigger with the omnifunc, <c-x><c-o>
vim.cmd([[
augroup DapRepl
  au!
  au FileType dap-repl lua require('dap.ext.autocompl').attach()
augroup END
]])
--

local dap_ui = require("dapui")

local _ = dap_ui.setup({
  layouts = {
    {
      elements = {
        "scopes",
        "breakpoints",
        "stacks",
        "watches",
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        "repl",
        "console",
      },
      size = 10,
      position = "bottom",
    },
  },
  -- -- You can change the order of elements in the sidebar
  -- sidebar = {
  --   elements = {
  --     -- Provide as ID strings or tables with "id" and "size" keys
  --     {
  --       id = "scopes",
  --       size = 0.75, -- Can be float or integer > 1
  --     },
  --     { id = "watches", size = 00.25 },
  --   },
  --   size = 50,
  --   position = "left", -- Can be "left" or "right"
  -- },
  --
  -- tray = {
  --   elements = {},
  --   size = 15,
  --   position = "bottom", -- Can be "bottom" or "top"
  -- },
})

-- listeners to automatically open dap-ui
dap.listeners.before.attach.dapui_config = function()
  dap_ui.open()
end

dap.listeners.before.launch.dapui_config = function()
  dap_ui.open()
end

-- listeners to automatically close dap-ui
dap.listeners.before.event_terminated["dapui_config"] = function()
  dap_ui.close()
end

dap.listeners.before.event_exited["dapui_config"] = function()
  dap_ui.close()
end

local ok, dap_go = pcall(require, "dap-go")
if ok then
  dap_go.setup()
end
