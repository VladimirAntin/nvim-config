-- Osnovna podešavanja
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'         -- Omogućava miš (korisno na početku)
vim.opt.termguicolors = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- Automatska instalacija Lazy.nvim (Plugin Manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Lista pluginova
require("lazy").setup({
  -- Tema (Izgled)
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function() vim.cmd[[colorscheme tokyonight]] end },
  
  -- Statusna linija (Dole)
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, config = true },
  
  -- Syntax Highlighting (Boje koda)
  { 
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate",
    lazy = false, -- Ovo osigurava da se učita odmah
    config = function()
      -- Koristimo pcall (protected call) da ne bi pukao ceo Neovim ako modul fali
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then 
        return 
      end
      
      configs.setup({
        ensure_installed = { "lua", "vim", "vimdoc", "javascript", "python" },
        highlight = { enable = true },
      })
    end 
  },

  -- Sidebar (Fajl menadžer) - otvara se sa :NvimTreeToggle
  { "nvim-tree/nvim-tree.lua", config = true },

  -- Telescope (Brza pretraga fajlova)
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
})


-- Brže kretanje između prozora (nema potrebe za ctrl+w)
vim.keymap.set('n', '<C-h>', '<C-w>h') -- Ctrl+h za levo
vim.keymap.set('n', '<C-j>', '<C-w>j') -- Ctrl+j za dole
vim.keymap.set('n', '<C-k>', '<C-w>k') -- Ctrl+k za gore
vim.keymap.set('n', '<C-l>', '<C-w>l') -- Ctrl+l za desno

-- Brzo kretanje kroz buffere (kao tabovi u Chrome-u)
-- Shift + l za sledeći, Shift + h za prethodni
vim.keymap.set('n', '<S-l>', ':bnext<CR>')
vim.keymap.set('n', '<S-h>', ':prev<CR>')

-- Prečica za File Explorer (nvim-tree)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>') -- Space + e otvara sidebar

-- Prečica za Telescope (traženje fajlova)
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {}) -- Space + ff traži fajlove
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})  -- Space + fg traži tekst u fajlovima

-- vim.opt.autochdir = true
