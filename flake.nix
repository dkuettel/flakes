{
  description = "synced common flake dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    # see https://pyproject-nix.github.io/uv2nix/usage/hello-world.html

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
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
        packages.default = flup;
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            nil
            nixfmt-rfc-style
          ];
          shellHook = ''
            if [[ -v h ]]; then
              export PATH=$h/bin:$PATH;
            else
              echo 'Project root env var h is not set.' >&2
            fi
          '';
        };
      }
    );
}
