# helper to build libraries
# this is a copy of what nixpkgs does, because it is not exposed to us
{ pkgs }:
let
  # install command
  withCommas = pkgs.lib.replaceStrings [ "." ] [ "," ];
  installHaxeLib = { libname, version, files ? "*", }: ''
    mkdir -p "$out/lib/haxe/${withCommas libname}/${withCommas version}"
    echo -n "${version}" > $out/lib/haxe/${withCommas libname}/.current
    cp -dpR ${files} "$out/lib/haxe/${withCommas libname}/${
      withCommas version
    }/"
  '';
in {
  inherit installHaxeLib;

  mkHaxelib = { libname, version, sha256 ? "", ... }@attrs:
    pkgs.stdenv.mkDerivation (attrs // {
      name = attrs.name or "${libname}-${version}";

      buildInputs = (attrs.buildInputs or [ ])
        ++ (with pkgs; [ haxe neko ]); # for setup-hook.sh to work
      src = attrs.src or (pkgs.fetchzip rec {
        name = "${libname}-${version}";
        url = "http://lib.haxe.org/files/3.0/${withCommas name}.zip";
        inherit sha256;
        stripRoot = false;
      });

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib/haxe/${withCommas libname}/${withCommas version}"
        echo -n "${version}" > $out/lib/haxe/${withCommas libname}/.current
        cp -dpR * "$out/lib/haxe/${withCommas libname}/${withCommas version}/"
        runHook postInstall
      '';

      postPatch = if libname == "lime" then ''
        # fdfdkfdf
          substituteInPlace ./tools/platforms/HTML5Platform.hx --replace 'System.runCommand(targetDirectory + "/bin", "npm", ["run", runCommand, "-s"]);' 'System.runCommand(${pkgs.nodejs_20}/bin/npm, ["run", runCommand, "-s"]);' 
          substituteInPlace ./src/lime/tools/HTML5Helper.hx --replace 'Sys.command("chmod", ["+x", node]);' ""
          substituteInPlace ./src/lime/tools/HTML5Helper.hx --replace 'var node = System.findTemplate(templatePaths, "bin/node/node" + suffix);'\
            'var node = ${pkgs.nodejs_20}/bin/node";'
          substituteInPlace ./src/lime/tools/HTML5Helper.hx --replace 'var server = System.findTemplate(templatePaths, "bin/node/http-server/bin/http-server");'\
            'var server = ${pkgs.http-server}/bin/http-server;'
      '' else
        "";

      meta = {
        homepage = "http://lib.haxe.org/p/${libname}";
        license = pkgs.lib.licenses.free;
        platforms = pkgs.lib.platforms.all;
        description = throw "please write meta.description";
      } // (attrs.meta or { });
    });
}
