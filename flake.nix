{
  description = "NixOS WSL Configuration Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-26.05";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-wsl,
      devshell,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ devshell.overlays.default ];
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixos-wsl.nixosModules.default
          ./modules
        ];
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;

      devShells.${system}.default = pkgs.devshell.mkShell {
        name = "nixos-wsl-config-devshell";

        packages = with pkgs; [
          deadnix
          git
          hostname
          nix-melt
          nix-output-monitor
          nix-tree
          statix
          tree
        ];

        commands = [
          {
            name = "rebuild";
            category = "system";
            help = "Rebuild NixOS-WSL system";
            command = ''
              nom build .#nixosConfigurations.''${1:-$(hostname)}.config.system.build.toplevel --no-link --show-trace --verbose \
                && sudo nixos-rebuild switch --flake .#''${1:-$(hostname)}
            '';
          }
          {
            name = "update";
            category = "maintenance";
            help = "Update flake inputs";
            command = "nix flake update";
          }
          {
            name = "check";
            category = "formatting";
            help = "Lint nix files (deadnix + statix)";
            command = ''
              echo "Running deadnix..."
              deadnix .
              echo "Running statix..."
              statix check
            '';
          }
          {
            name = "fmt";
            category = "formatting";
            help = "Format nix files";
            command = "nix fmt";
          }
        ];
      };
    };
}
