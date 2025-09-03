{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    backblaze-b2
    terraform
    vault-bin
  ];
}
