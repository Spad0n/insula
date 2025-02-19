let pkgs = import <nixpkgs> { };
in pkgs.mkShell {
  buildInputs = with pkgs; [
    sdl3
    wabt
    libGL
    alsa-lib
  ];

  shellHook = ''
    unset WAYLAND_DISPLAY
  '';

  LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
    with pkgs;
    pkgs.lib.makeLibraryPath [ libGL alsa-lib ]
  }";
}
