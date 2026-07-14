# Claude Code plugin carrying the full declarative Claude configuration:
# language servers (native LSP support) and MCP servers. Loaded
# session-locally via `--plugin-dir` in the claude wrapper (flake.nix) — no
# marketplace, no interactive install, nothing written to ~/.claude.
#
# Every LSP `command` below must be on the claude wrapper's PATH: they come
# from editorPackages (packages/dependencies) plus rust-analyzer from the
# rust-overlay toolchain. Keep the two lists in sync. MCP servers reference
# absolute store paths instead, so they need no PATH entry.
{ pkgs }:
let
  lspServers = {
    bash = {
      command = "bash-language-server";
      args = [ "start" ];
      extensionToLanguage = {
        ".sh" = "shellscript";
        ".bash" = "shellscript";
      };
    };
    c-cpp = {
      command = "clangd";
      extensionToLanguage = {
        ".c" = "c";
        ".h" = "c";
        ".cpp" = "cpp";
        ".cc" = "cpp";
        ".cxx" = "cpp";
        ".hpp" = "cpp";
      };
    };
    # Matching is extension-based, so bare CMakeLists.txt files are not
    # routed to the server; *.cmake modules are.
    cmake = {
      command = "cmake-language-server";
      extensionToLanguage.".cmake" = "cmake";
    };
    css = {
      command = "vscode-css-language-server";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".css" = "css";
        ".scss" = "scss";
        ".less" = "less";
      };
    };
    # Extension-based matching: only *.dockerfile, not bare `Dockerfile`.
    docker = {
      command = "docker-langserver";
      args = [ "--stdio" ];
      extensionToLanguage.".dockerfile" = "dockerfile";
    };
    html = {
      command = "vscode-html-language-server";
      args = [ "--stdio" ];
      extensionToLanguage.".html" = "html";
    };
    json = {
      command = "vscode-json-language-server";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".json" = "json";
        ".jsonc" = "jsonc";
      };
    };
    lua = {
      command = "lua-language-server";
      extensionToLanguage.".lua" = "lua";
    };
    markdown = {
      command = "marksman";
      args = [ "server" ];
      extensionToLanguage.".md" = "markdown";
    };
    nix = {
      command = "nixd";
      extensionToLanguage.".nix" = "nix";
    };
    python = {
      command = "basedpyright-langserver";
      args = [ "--stdio" ];
      extensionToLanguage.".py" = "python";
    };
    rust = {
      command = "rust-analyzer";
      extensionToLanguage.".rs" = "rust";
    };
    svelte = {
      command = "svelteserver";
      args = [ "--stdio" ];
      extensionToLanguage.".svelte" = "svelte";
    };
    toml = {
      command = "taplo";
      args = [
        "lsp"
        "stdio"
      ];
      extensionToLanguage.".toml" = "toml";
    };
    typescript = {
      command = "typescript-language-server";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".ts" = "typescript";
        ".tsx" = "typescriptreact";
        ".js" = "javascript";
        ".jsx" = "javascriptreact";
        ".mjs" = "javascript";
        ".mts" = "typescript";
      };
    };
    xml = {
      command = "lemminx";
      extensionToLanguage.".xml" = "xml";
    };
    yaml = {
      command = "yaml-language-server";
      args = [ "--stdio" ];
      extensionToLanguage = {
        ".yaml" = "yaml";
        ".yml" = "yaml";
      };
    };
  };

  # Replaces the marketplace context7 plugin (`npx -y @upstash/context7-mcp`)
  # with the nixpkgs-packaged server: pinned, cached, no npm fetch at startup.
  mcpServers = {
    context7 = {
      command = "${pkgs.context7-mcp}/bin/context7-mcp";
    };
  };

  manifest = {
    name = "nix-dev";
    description = "Declarative Claude Code config from the dev flake: language servers and MCP servers";
    version = "1.0.0";
    lspServers = "./.lsp.json";
    mcpServers = "./.mcp.json";
  };
in
pkgs.runCommand "claude-plugin"
  {
    passAsFile = [
      "manifest"
      "lsp"
      "mcp"
    ];
    manifest = builtins.toJSON manifest;
    lsp = builtins.toJSON lspServers;
    mcp = builtins.toJSON mcpServers;
    nativeBuildInputs = [ pkgs.jq ];
  }
  ''
    mkdir -p $out/.claude-plugin
    jq . "$manifestPath" > $out/.claude-plugin/plugin.json
    jq . "$lspPath" > $out/.lsp.json
    jq . "$mcpPath" > $out/.mcp.json
  ''
