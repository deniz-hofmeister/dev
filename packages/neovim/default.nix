{ pkgs }:
let
  customRC = import ./config { inherit pkgs; };
  plugins = import ./plugins { inherit pkgs; };
  dependencies = import ../dependencies  { inherit pkgs; };
  
  # Extract the path to OpenDebugAD7
  cpptools = pkgs.vscode-extensions.ms-vscode.cpptools;
  cpptoolsPath = "${cpptools}/share/vscode/extensions/ms-vscode.cpptools";
  
  neovimRuntimeDependencies = pkgs.symlinkJoin {
    name = "neovimRuntimeDependencies";
    paths = dependencies.packages;
    postBuild = ''
      for f in $out/lib/node_modules/.bin/*; do
         path="$(readlink --canonicalize-missing "$f")"
         ln -s "$path" "$out/bin/$(basename $f)"
      done
      
      # Create a symlink to OpenDebugAD7 in the bin directory
      mkdir -p $out/bin
      ln -s ${cpptoolsPath}/bin/OpenDebugAD7 $out/bin/OpenDebugAD7
    '';
  };
  
  NeovimUnwrapped = pkgs.wrapNeovim pkgs.neovim {
    configure = {
      inherit customRC;
      packages.all.start = plugins;
    };
  };
in
  pkgs.writeShellApplication {
  name = "nvim";
  runtimeInputs = [ neovimRuntimeDependencies ];
  text = ''
    ${NeovimUnwrapped}/bin/nvim "$@"
  '';
}
