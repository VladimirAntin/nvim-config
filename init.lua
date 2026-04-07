-- 1. OSNOVNA PODEŠAVANJA (Options)
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.cursorline = true

-- 2. LAZY.NVIM INSTALACIJA
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 3. PLUGINI
require("lazy").setup({
  -- Izgled
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function() vim.cmd[[colorscheme tokyonight]] end },
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = true },

  -- TREESITTER (Ispravljen)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Koristimo pcall da sprečimo "module not found" grešku pri prvom paljenju
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then return end
      configs.setup({
        ensure_installed = { "lua", "vim", "javascript", "typescript", "json", "html", "css" },
        highlight = { enable = true },
      })
    end
  },

  -- Sidebar
  { "nvim-tree/nvim-tree.lua", config = { actions = { open_file = { quit_on_open = true } } } },

  -- Telescope
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },

  -- LSP & FORMATTING (Moderni 0.12 pristup)
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

      -- NOVI SISTEM: Koristimo vim.lsp.enable (Neovim 0.11/0.12+)
      local servers = { "ts_ls", "eslint", "html", "cssls" }
      for _, server in ipairs(servers) do
        vim.lsp.enable(server)
      end

      -- Prettier (None-ls)
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
            if client.supports_method("textDocument/formatting") then
              vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
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
})

-- 4. PREČICE
local keymap = vim.keymap.set
keymap('n', '<leader>e', ':NvimTreeToggle<CR>')
keymap('n', '<leader>ff', ':Telescope find_files<CR>')
keymap('n', 'gd', vim.lsp.buf.definition)
keymap('n', 'K', vim.lsp.buf.hover)
