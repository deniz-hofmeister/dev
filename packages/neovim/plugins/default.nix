{ pkgs }:
with pkgs.vimPlugins;
[
  # Treesitter (main branch): parsers + queries kept in lockstep by nixpkgs
  (nvim-treesitter.withPlugins (
    plugins: with plugins; [
      bash
      c
      cmake
      cpp
      css
      diff
      dockerfile
      doxygen
      gitcommit
      html
      javascript
      json
      lua
      markdown
      markdown_inline
      nix
      python
      query
      regex
      rust
      svelte
      toml
      tsx
      typescript
      vim
      vimdoc
      xml
      yaml
    ]
  ))
  nvim-treesitter-textobjects

  # LSP (data-only configs consumed via vim.lsp.config/enable)
  nvim-lspconfig

  # Completion
  blink-cmp
  friendly-snippets

  # Formatting / linting
  conform-nvim
  nvim-lint

  # Debugging
  nvim-dap
  nvim-dap-view
  nvim-dap-python

  # Testing
  neotest
  neotest-python
  neotest-ctest

  # Rust
  rustaceanvim
  crates-nvim

  # C++ / CMake
  cmake-tools-nvim

  # Git
  gitsigns-nvim
  vim-fugitive
  diffview-plus-nvim

  # Pickers / navigation
  telescope-nvim
  telescope-fzf-native-nvim
  neo-tree-nvim
  oil-nvim
  trouble-nvim

  # UI
  catppuccin-nvim
  lualine-nvim
  nvim-web-devicons
  which-key-nvim
  todo-comments-nvim
  render-markdown-nvim
  mini-nvim
]
