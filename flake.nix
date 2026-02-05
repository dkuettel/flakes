{
  description = "synced common flake dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      flup = pkgs.writeScriptBin "flup" ''
        #!${pkgs.zsh}/bin/zsh
        set -eu -o pipefail
        overrides=(
          --override-input nixpkgs github:NixOS/nixpkgs/${self.inputs.nixpkgs.rev}
          --override-input unstable github:NixOS/nixpkgs/${self.inputs.unstable.rev}
          --override-input flake-utils github:numtide/flake-utils/${self.inputs.flake-utils.rev}
        )
        flake update $overrides $@
      '';
    in
    {
      packages.x86_64-linux.default = flup;
    };
}
