{ pkgs, haxelib, haxe_4_3_3, format_latest, lime }:

let
  openfl_9_3_2 = haxelib.mkHaxelib {
    libname = "openfl";
    version = "9.3.2";
    sha256 = "";
  };

  mkProjectXml = { name, version, }:
    pkgs.writeText "project.xml" ''
      <?xml version="1.0" encoding="utf-8"?>
      <project>
      	<meta title="${name}" package="${name}" version="${version}" company="none" />
      	<app main="Main" path="export" file="${name}" />
      	<source path="src" />
        <haxelib name="openfl" />
      	<assets path="Assets" rename="assets" />
      </project>
    '';
in {
  inherit openfl_9_3_2;

  mkShell = openflGame:
    pkgs.mkShell {
      buildInputs = openflGame.buildInputs;
      inputsFrom = [ openflGame ];
    };

  mkGame = { name, version, src, target }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-${version}";
      inherit src;
      buildInputs = [ openfl_9_3_2 lime.lime_8_1_1 lime.hxp_1_3_0 ];

      unpackPhase = ''
        export HOME=$(mktemp -d)
        cp -r $src/src ./
        cp -r $src/Assets ./
        ln -s ${mkProjectXml { inherit name version; }} ./project.xml
      '';

      buildPhase = ''
        mkdir export
        ${haxe_4_3_3}/bin/haxelib run openfl build ${target} -eval
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp -r export/${target}/bin/* $out/bin/
      '';
    };

}
