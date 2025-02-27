# CLAUDE.md - Codebase Guidelines

## Build & Run Commands
- Build project: `nix build`
- Run project: `nix run`
- Run neovim: `nix run .#neovim`
- Run zsh shell: `nix run .#zsh`
- Format nix files: `nixfmt *.nix`

## Code Style Guidelines

### Nix
- Use 2-space indentation
- Follow RFC Nix style for formatting
- Use `with pkgs;` for standard packages 
- Use explicit attribute sets for custom packages

### Lua
- Use 2-space indentation
- Format with stylua
- Format on save is configured via conform.nvim
- Prefer explicit imports (`local x = require("x")`)
- Group plugin configurations into logical sections
- Follow neovim lua API style guidelines

### Project Structure
- `/packages`: Contains all packages defined in the flake
- `/packages/neovim`: Neovim configuration
- `/packages/dependencies`: System dependencies
- Maintain separation between plugins, config and keymaps