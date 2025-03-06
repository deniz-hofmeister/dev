{ pkgs }:
let
  customRC = import ./config { inherit pkgs; };
  plugins = import ./plugins { inherit pkgs; };
  dependencies = import ../dependencies { inherit pkgs; };

  neovimRuntimeDependencies = pkgs.symlinkJoin {
    name = "neovimRuntimeDependencies";
    paths = dependencies.packages;
    postBuild = ''
      for f in $out/lib/node_modules/.bin/*; do
         path="$(readlink --canonicalize-missing "$f")"
         ln -s "$path" "$out/bin/$(basename $f)"
      done
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
    export OPENSSL_ROOT_DIR=${pkgs.openssl.dev}
    export OPENSSL_LIBRARIES=${pkgs.openssl.out}/lib
    export OPENSSL_INCLUDE_DIR=${pkgs.openssl.dev}/include
    export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig
    export spdlog_DIR=${pkgs.spdlog.dev}/lib/cmake/spdlog
    export fmt_DIR=${pkgs.fmt}/lib/cmake/fmt
    # export CMAKE_PREFIX_PATH=${pkgs.spdlog.dev}:${pkgs.fmt}:''${CMAKE_PREFIX_PATH:-}
    ${NeovimUnwrapped}/bin/nvim "$@"
  '';
}
