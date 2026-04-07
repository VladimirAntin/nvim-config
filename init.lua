-- 1. OSNOVNA PODEŠAVANJA (Options)
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.cursorline = true

-- 1. OSNOVNA PODEŠAVANJA (Options)
vim.opt.shiftwidth = 2   -- Broj razmaka za automatsku indentaciju
vim.opt.tabstop = 2      -- Broj razmaka koje TAB karakter predstavlja
vim.opt.softtabstop = 2  -- Broj razmaka koje TAB unosi dok kucaš
vim.opt.expandtab = true -- Pretvara svaki TAB u razmake (spaces)


-- CLIPBOARD (Sistemski clipboard za macOS)
vim.opt.clipboard = "unnamedplus"
if vim.fn.has('mac') == 1 then
    vim.g.clipboard = {
        name = 'macOS-clipboard',
        copy = { ['+'] = 'pbcopy', ['*'] = 'pbcopy' },
        paste = { ['+'] = 'pbpaste', ['*'] = 'pbpaste' },
        cache_enabled = 0,
    }
end

-- 2. LAZY.NVIM INSTALACIJA
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)


-- Vizuelno podešavanje za neiskorišćeni kod (Diagnostics)
vim.diagnostic.config({
  virtual_text = {
    prefix = '●', -- Tačkica ispred poruke
  },
  update_in_insert = false,
  underline = true,
  severity_sort = true,
})

-- Promeni boju neiskorišćenih varijabli da budu "izbledele"
vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { link = "Comment", italic = true })

-- 3. PLUGINI
require("lazy").setup({
  -- Izgled
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function() vim.cmd[[colorscheme tokyonight]] end },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = true },

  -- TREESITTER (Syntax Highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      configs.setup({
        ensure_installed = { "lua", "vim", "javascript", "typescript", "tsx", "json", "html", "css" },
        highlight = { enable = true },
        -- ISKLJUČENO ovde da ne bi pravilo konflikt sa nvim-ts-autotag
        autotag = { enable = false }, 
      })
    end
  },

  -- Sidebar & Telescope
  { "nvim-tree/nvim-tree.lua", config = { actions = { open_file = { quit_on_open = true } } } },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },

  -- LSP & FORMATTING
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "ts_ls", "eslint", "html", "cssls" }
      })

      -- Moderni Neovim 0.12 LSP
      local servers = { "ts_ls", "eslint", "html", "cssls" }
      for _, server in ipairs(servers) do
        vim.lsp.enable(server)
      end

      -- Prettier Setup
      local ok, null_ls = pcall(require, "null-ls")
      if ok then
        local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
        null_ls.setup({
          sources = {
            null_ls.builtins.formatting.prettier.with({
              condition = function(utils)
                return utils.root_has_file({ ".prettierrc", ".prettierrc.json", ".prettierrc.js", "package.json" })
              end,
            }),
          },
          on_attach = function(client, bufnr)
            if client:supports_method("textDocument/formatting") then
              vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup, buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({ bufnr = bufnr, filter = function(c) return c.name == "null-ls" end })
                end,
              })
            end
         end,
        })
      end
    end
  },

  -- SNIPPETS (React prečice)
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- AUTOCOMPLETION
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- JSX TAGOVI (Ispravljeno)

  -- Zamena za autotag: Mnogo stabilnija opcija koja ne koristi Treesitter
  {
    "alvan/vim-closetag",
    -- Učitava se samo za ove tipove fajlova (React, HTML...)
    ft = { 
      "html", "javascript", "typescript", 
      "javascriptreact", "typescriptreact", "xml" 
    },
    config = function()
      -- Gde sve želiš da radi automatsko zatvaranje
      vim.g.closetag_filenames = "*.html,*.xhtml,*.phtml,*.jsx,*.tsx"
      
      -- Ovo je KLJUČNO za React: kaže pluginu da su .jsx i .tsx zapravo JSX regioni
      vim.g.closetag_regions = {
        ["typescript.tsx"] = "jsxRegion",
        ["javascript.jsx"] = "jsxRegion",
        ["typescriptreact"] = "jsxRegion",
        ["javascriptreact"] = "jsxRegion",
      }
      
      -- Opciono: zatvaraj tagove i za samozatvarajuće (poput <br />)
      vim.g.closetag_emptyTags_caseSensitive = 1
      
      -- Prečica: ako želiš ručno da zatvoriš tag (opciono)
      vim.g.closetag_shortcut = ">"
    end
  },

  -- ZAGRADE
  { "windwp/nvim-autopairs", config = true },
})

-- 4. PREČICE (Keymaps)
local keymap = vim.keymap.set
keymap('n', '<leader>e', ':NvimTreeToggle<CR>')
keymap('n', '<leader>ff', ':Telescope find_files<CR>')
keymap('n', 'gd', vim.lsp.buf.definition)
keymap('n', 'K', vim.lsp.buf.hover)
keymap('n', '<leader>ca', vim.lsp.buf.code_action)
