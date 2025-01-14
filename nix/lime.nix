# lime.nix
{ pkgs, haxelib, haxe_4_3_3, format_latest, }:
let
  lime_8_1_1 = haxelib.mkHaxelib {
    libname = "lime";
    name = "lime8";
    version = "8.1.1";
    sha256 = "sha256-bOwe+jNymk+5liOv0eoFlNtrYxLBlxivntFnrQDDgKU=";
    buildInputs = with pkgs; [ nodejs_20 http-server ];
    # postPatch = ''
    #   substituteInPlace ./tools/platforms/HTML5Platform.hx --replace 'System.runCommand(targetDirectory + "/bin", "npm", ["run", runCommand, "-s"]);' 'System.runCommand(${pkgs.nodejs_20}/bin/npm, ["run", runCommand, "-s"]);' 
    #   substituteInPlace ./src/lime/tools/HTML5Helper.hx --replace 'Sys.command("chmod", ["+x", node]);' ""
    #   substituteInPlace ./src/lime/tools/HTML5Helper.hx --replace 'var node = System.findTemplate(templatePaths, "bin/node/node" + suffix);'\
    #     'var node = ${pkgs.nodejs_20}/bin/node"'
    #   substituteInPlace ./src/lime/tools/HTML5Helper.hx --replace 'var server = System.findTemplate(templatePaths, "bin/node/http-server/bin/http-server");'\
    #     'var server = ${pkgs.http-server}/bin/http-server'
    # '';
  };

  hxp_1_3_0 = haxelib.mkHaxelib {
    libname = "hxp";
    version = "1.3.0";
    sha256 = "sha256-h1vziyWzJUk/pHGkkMO1gMrs38rdhKjp9HYi6+QBbCM=";
  };

  mkProjectXml = { name, version, }:
    pkgs.writeText "project.xml" ''
      <?xml version="1.0" encoding="utf-8"?>
      <project>
      	<meta title="${name}" package="${name}" version="${version}" company="none" />
      	<app main="Main" path="export" file="${name}" />
      	<source path="src" />
      	<haxelib name="lime" />
      	<assets path="Assets" rename="assets" />
      </project>
    '';
in {
  inherit lime_8_1_1;

  mkShell = limeGame:
    pkgs.mkShell {
      # nativeBuildInputs = buildLibs;
      buildInputs = limeGame.buildInputs;
      inputsFrom = [ limeGame ];
    };

  # not really a 'game', but I'll stick with the convention
  mkGame = { name, version, src, target, }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-${version}";
      inherit src;
      # nativeBuildInputs = [lime_8_1_1 haxe_latest pkgs.neko format_latest];
      buildInputs = [ lime_8_1_1 haxe_4_3_3 pkgs.neko format_latest hxp_1_3_0 ];
      unpackPhase = ''
        export HOME=$(mktemp -d)
        cp -r $src/src ./
        cp -r $src/Assets ./
        ln -s ${mkProjectXml { inherit name version; }} ./project.xml
      '';

      buildPhase = ''
        mkdir export
        ${haxe_4_3_3}/bin/haxelib run lime build ${target} -eval
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp -r export/${target}/bin/* $out/bin/
      '';
    };
}
