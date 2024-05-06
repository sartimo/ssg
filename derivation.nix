{ lib, pkgs }:

pkgs.stdenv.mkDerivation {
  name = "ssg";
  src = ./.;
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp ssg $out/bin/
  '';
  meta = {
    description = "a minimalist ssg based on nix that powers tc.cli.rs";
    homepage = "https://github.com/sartimo/ssg";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ sartimo ];
    platforms = lib.platforms.all;
  };
}
