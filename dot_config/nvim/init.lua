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
  cmd = { "uvx", "ty", "server" },
  filetypes = { "python" },
  root_markers = { ".git", "pyproject.toml" },
})

vim.lsp.config("ruff", {
  cmd = { 'uvx', 'ruff', 'server' },
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
  -- icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  -- treesitter (markdown parsers)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "markdown", "markdown_inline", "yaml", "html", "latex" },
    },
  },
  -- inline markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  -- lean
  {
    "Julian/lean.nvim",
    event = { "BufReadPre *.lean", "BufNewFile *.lean" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
    },
    opts = {
      mappings = true,
      infoview = {
        autoopen = true,
      },
    },
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

      vim.keymap.set("n", "<C-p>", fzf.files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader><leader>", fzf.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fo", fzf.oldfiles, { desc = "Recent files" })
      vim.keymap.set("n", "<leader>r", fzf.resume, { desc = "Resume picker" })
      vim.keymap.set("n", "gd", fzf.lsp_definitions, { desc = "Go to definition" })
      vim.keymap.set("n", "gr", fzf.lsp_references, { desc = "Go to references" })
    end,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      skip_confirm_for_simple_edits = true,
      keymaps = {
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
      },
    },
    config = function(_, opts)
      require("oil").setup(opts)
      vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Oil" })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      vim.keymap.set("n", "]h", "<cmd>Gitsigns next_hunk<cr>", { desc = "Next hunk" })
      vim.keymap.set("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Prev hunk" })
      vim.keymap.set("n", "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", { desc = "Stage hunk" })
      vim.keymap.set("n", "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })
      vim.keymap.set("n", "<leader>hb", "<cmd>Gitsigns blame_line<cr>", { desc = "Blame line" })
    end,
  },
  { "sindrets/diffview.nvim" },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    config = function()
      require("neogit").setup({})
      vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
      vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview" })
    end,
  }
})
