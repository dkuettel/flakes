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
        flupq = pkgs.writeScriptBin "flupq" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          overrides=(
            --override-input nixpkgs github:NixOS/nixpkgs/${self.inputs.nixpkgs.rev}
            --override-input unstable github:NixOS/nixpkgs/${self.inputs.unstable.rev}
            --override-input flake-utils github:numtide/flake-utils/${self.inputs.flake-utils.rev}
            --override-input pyproject-nix github:pyproject-nix/pyproject.nix/${self.inputs.pyproject-nix.rev}
            --override-input uv2nix github:pyproject-nix/uv2nix/${self.inputs.uv2nix.rev}
            --override-input pyproject-build-systems github:pyproject-nix/build-system-pkgs/${self.inputs.pyproject-build-systems.rev}
          )
          flake update $overrides --quiet --quiet $@
        '';
        flup = pkgs.writeScriptBin "flup" ''
          #!${pkgs.zsh}/bin/zsh
          set -eu -o pipefail
          ${flupq}/bin/flupq $@
          echo 'Note that input overrides are purely based on input names, not their defined values.'
        '';
        env = pkgs.buildEnv {
          name = "flup";
          paths = [flup flupq];
        };
      in
      {
        packages.default = env;
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
