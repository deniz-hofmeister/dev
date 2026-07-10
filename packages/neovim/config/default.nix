# Source every file in ./lua in lexicographic order — the numeric filename
# prefixes define the load order.
let
  files = builtins.attrNames (builtins.readDir ./lua);
in
builtins.concatStringsSep "\n" (builtins.map (file: "luafile ${./lua}/${file}") files)
