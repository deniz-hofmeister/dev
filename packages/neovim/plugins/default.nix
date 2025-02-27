{ pkgs }:
with pkgs.vimPlugins;
[
  (nvim-treesitter.withPlugins (plugins: with plugins; [ xml ]))
  catppuccin-nvim
  cmp-buffer
  cmp-cmdline
  cmp-nvim-lsp
  cmp-path
  cmp_luasnip
  conform-nvim
  gitsigns-nvim
  lsp_lines-nvim
  lualine-nvim
  luasnip
  markview-nvim
  mini-nvim
  neo-tree-nvim
  neotest
  noice-nvim
  nvim-cmp
  nvim-dap
  nvim-dap-ui
  nvim-dap-virtual-text
  nvim-lspconfig
  nvim-web-devicons
  oil-nvim
  rustaceanvim
  telescope-fzf-native-nvim
  telescope-nvim
  todo-comments-nvim
  trouble-nvim
  vim-fugitive
  vim-nix
  which-key-nvim
]
