let pkgs = import <nixpkgs> { };
in pkgs.mkShell {
  buildInputs = with pkgs; [
    sdl3
    wabt
    libGL
    alsa-lib
  ];

  LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
    with pkgs;
    pkgs.lib.makeLibraryPath [ libGL alsa-lib ]
  }";
}
