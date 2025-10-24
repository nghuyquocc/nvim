local vo = vim.opt

vo.number         = true
vo.relativenumber = true
vo.expandtab      = true
vo.smartindent    = true
vo.ignorecase     = true
vo.smartcase      = true
vo.termguicolors  = true
vo.cursorline     = true
vo.wrap           = false
vo.splitbelow     = true
vo.splitright     = true
vo.hidden         = true

-- UI cleanup
vo.signcolumn     = "yes"
vo.colorcolumn    = ""         -- no vertical ruler
vo.showmode       = true       -- show -- INSERT --
vo.showtabline    = 2          -- show tabs at top
vo.laststatus     = 0          -- minimal: no bottom statusline

-- misc
vo.mouse          = "a"
vo.clipboard      = "unnamedplus"
vo.tabstop        = 4
vo.shiftwidth     = 4
vo.scrolloff      = 8
vo.updatetime     = 300
vo.timeoutlen     = 300

vim.g.mapleader   = " "

-- ========= lazy.nvim bootstrap =========
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- Kanagawa (transparent + scrub side colors)
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = false,
      dimInactive = false,
      terminalColors = true,
      transparent = true,
      transparent_background = true,
      theme = "wave",
      background = { dark = "wave", light = "lotus" },
      overrides = function(colors)
        return {
          Normal        = { bg = "none" },
          NormalNC      = { bg = "none" },
          NormalFloat   = { bg = "none" },
          FloatBorder   = { bg = "none", fg = colors.palette.sumiInk4 },

          SignColumn    = { bg = "none" },
          LineNr        = { bg = "none" },
          CursorLineNr  = { bg = "none" },
          FoldColumn    = { bg = "none" },

          VertSplit     = { bg = "none", fg = colors.palette.sumiInk4 },
          WinSeparator  = { bg = "none", fg = colors.palette.sumiInk4 },

          StatusLine    = { bg = "none" },
          StatusLineNC  = { bg = "none" },

          TabLine       = { bg = "none" },
          TabLineSel    = { bg = "none" },
          TabLineFill   = { bg = "none" },

          ColorColumn   = { bg = "none" },
          CursorLine    = { bg = colors.palette.sumiInk2 },
          EndOfBuffer   = { fg = "none", bg = "none" },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },

  -- Top tabs with close button
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        always_show_bufferline  = true,
        show_buffer_close_icons = true,   -- show × on each tab
        show_close_icon         = false,  -- no global close
        separator_style         = "thin",
        diagnostics             = "nvim_lsp",

        -- ✅ Use templates so bufferline injects the buffer number
        close_command           = "bdelete! %d",
        right_mouse_command     = "bdelete! %d",
        middle_mouse_command    = "bdelete! %d",
      },
    },
    config = function(_, opts) require("bufferline").setup(opts) end,
  },

  -- Floating terminal
  {
    "voldikss/vim-floaterm",
    config = function()
      vim.g.floaterm_keymap_toggle = "<leader>t"
      vim.g.floaterm_title = "Terminal"
    end,
  },

  -- Icons
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function() require("gitsigns").setup() end,
  },

  -- Telescope + FZF
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make",
        cond = function() return vim.fn.executable("make") == 1 end },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          prompt_prefix    = "  ",
          selection_caret  = " ",
          sorting_strategy = "ascending",
          layout_config    = { prompt_position = "top" },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- CMP + snippets
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fb)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fb() end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fb)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fb() end
          end, { "i", "s" }),
        }),
        sources = { { name = "buffer" }, { name = "path" }, { name = "luasnip" } },
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },

  -- LSP (Neovim 0.11 API)
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    config = function()
      require("mason").setup()

      local mlsp = require("mason-lspconfig")
      local servers = { "clangd", "pyright" }

      mlsp.setup({ ensure_installed = servers, automatic_installation = true })

      local ok, installed = pcall(mlsp.get_installed_servers)
      if not ok or #installed == 0 then installed = servers end

      for _, server in ipairs(installed) do
        vim.lsp.enable(server, {
          -- add on_attach/capabilities/settings here if needed
        })
      end

      -- LSP keymaps
      local map = vim.keymap.set
      local km  = { noremap = true, silent = true }
      map("n", "gd", vim.lsp.buf.definition, km)
      map("n", "K",  vim.lsp.buf.hover, km)
      map("n", "<leader>rn", vim.lsp.buf.rename, km)
      map("n", "<leader>ca", vim.lsp.buf.code_action, km)
      map("n", "gr", vim.lsp.buf.references, km)
    end,
  },

})

-- ========= keymaps =========
local map  = vim.keymap.set
local base = { noremap = true, silent = true }
local function nmap(lhs, rhs, desc) map("n", lhs, rhs, vim.tbl_extend("force", base, { desc = desc })) end

-- Quick close “tab”
nmap("<leader>c", ":bdelete!<CR>", "Close tab (buffer)")

-- Files / windows
nmap("<leader>w", ":w<CR>",   "Save file")
nmap("<leader>q", ":q<CR>",   "Quit window")
nmap("Q",         ":q!<CR>",  "Force quit")

-- Floaterm toggle
nmap("<leader>t", ":FloatermToggle<CR>", "Toggle floating terminal")

-- Telescope
nmap("<leader>ff", "<cmd>Telescope find_files<CR>", "Find files")
nmap("<leader>fg", "<cmd>Telescope live_grep<CR>",  "Live grep")
nmap("<leader>fb", "<cmd>Telescope buffers<CR>",    "Buffers")
nmap("<leader>fh", "<cmd>Telescope help_tags<CR>",  "Help")

-- Smooth motions
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")
map("n", "J",     "mzJ`z")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Terminal buffer keymaps
vim.api.nvim_create_autocmd("TermOpen", {
  pattern  = "term://*",
  callback = function()
    local topts = { noremap = true, silent = true, buffer = true, desc = "Close floating terminal" }
    vim.keymap.set("t", "<leader>q", "<C-\\><C-n>:FloatermHide<CR>", topts)
  end,
})

-- Allow closing the last tab cleanly: when the final buffer closes, open a blank one
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    if vim.fn.bufnr("$") == 1 then
      vim.cmd("enew")
    end
  end,
})
