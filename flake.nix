{
  description = "nvim-air: a flake exporting a small, fast Neovim";

  # INPUTS
  # ------------------------------------------------
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # --- Plugins built from source (prefix "plugins-") ---
    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };

    plugins-lzextras = {
      url = "github:BirdeeHub/lzextras";
      flake = false;
    };
  };

  # OUTPUTS
  # ------------------------------------------------
  outputs =
    inputs@{
      self,
      nixpkgs,
      wrappers,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ wrappers.flakeModules.wrappers ];
      systems = nixpkgs.lib.platforms.all;

      perSystem =
        { config, ... }:
        {
          packages.default = config.packages.nvim-air;
        };

      flake = {
        # The wrapper lives under `wrappers.nvim-air`
        wrappers.nvim-air = nixpkgs.lib.modules.importApply ./module.nix inputs;

        nixosModules = {
          nvim-air = wrappers.lib.getInstallModule {
            name = "nvim-air";
            value = self.wrapperModules.nvim-air;
          };
          default = self.nixosModules.nvim-air;
        };

        homeModules = {
          nvim-air = wrappers.lib.getInstallModule {
            name = "nvim-air";
            value = self.wrapperModules.nvim-air;
          };
          default = self.homeModules.nvim-air;
        };

        overlays = {
          nvim-air = final: _: {
            nvim-air = self.wrappers.nvim-air.wrap { pkgs = final; };
          };
          default = self.overlays.nvim-air;
        };
      };
    };
}
