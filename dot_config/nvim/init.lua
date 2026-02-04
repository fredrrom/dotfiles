-- leader (must be first)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.updatetime = 200
vim.opt.timeoutlen = 300

vim.opt.clipboard = "unnamedplus"

-- lsps
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".git", ".luarc.json", ".luarc.jsonc" },
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,          -- Neovim runtime files
          vim.fn.stdpath("config"),    -- your nvim config
        },
      },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("ty", {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = { ".git", "pyproject.toml" },
})

vim.lsp.config("ruff", {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  settings = {},
})

vim.lsp.enable({ "ty", "ruff", "lua_ls" })

-- diagnostics 
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

vim.diagnostic.config({
  float = {
    border = "rounded",
    source = "if_many",
    focusable = false,
    max_width = 80,
  },
})

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- plugins
require("lazy").setup({
  -- theme (catppuccin mocha)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        integrations = {
          treesitter = true,
          native_lsp = { enabled = true },
          fzf = true,
          cmp = true,
          gitsigns = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  -- vim-tmux navigation
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  -- comments
  {
    "numtostr/comment.nvim",
    opts = {},
  },
  -- fzf-lua (files / grep)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local fzf = require("fzf-lua")

      fzf.setup({
        files = { fd_opts = "--hidden --follow --exclude .git" },
        grep = {
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git/*'",
        },
      })

      vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "find files (cwd)" })
      vim.keymap.set("n", "<leader>fh", function()
        fzf.files({ cwd = vim.fn.expand("~") })
      end, { desc = "find files (home)" })

      vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "live grep" })
      vim.keymap.set("n", "<leader>fb", fzf.buffers,   { desc = "buffers" })
      vim.keymap.set("n", "<leader>fr", fzf.oldfiles,  { desc = "recent files" })
      vim.keymap.set("n", "<leader>fc", fzf.commands,  { desc = "commands" })
    end,
  },
  -- opencode (NickvanDyke)
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      vim.g.opencode_opts = {
        provider = {
          enabled = "tmux",
          tmux = {
            options = "-h",
            focus = true,
            allow_passthrough = false,
          },
        },
      }

      vim.o.autoread = true
      local oc = require("opencode")

      -- recommended core keymaps
      vim.keymap.set({ "n", "x" }, "<C-a>", function()
        oc.ask("@this: ", { submit = true })
      end, { desc = "Ask opencode" })
      vim.keymap.set({ "n", "x" }, "<C-x>", oc.select, { desc = "Execute opencode action" })
      vim.keymap.set({ "n", "t" }, "<C-_>", oc.toggle, { desc = "Toggle opencode" })

      vim.keymap.set({ "n", "x" }, "go", function()
        return oc.operator("@this ")
      end, { expr = true, desc = "Add range to opencode" })

      vim.keymap.set("n", "goo", function()
        return oc.operator("@this ") .. "_"
      end, { expr = true, desc = "Add line to opencode" })

      vim.keymap.set("n", "<S-C-u>", function()
        oc.command("session.half.page.up")
      end, { desc = "Scroll opencode up" })
      vim.keymap.set("n", "<S-C-d>", function()
        oc.command("session.half.page.down")
      end, { desc = "Scroll opencode down" })
   end,
  }
})
