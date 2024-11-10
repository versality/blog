let
  stable = import <nixos> { };
  unstable = import <nixos-unstable> { };
in
stable.mkShell {
  buildInputs = [
    stable.pandoc
    stable.yq
  ];

  shellHook = ''
  '';
}
