{
  description = "airnvim: a flake exporting a small, fast Neovim";

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
          packages.default = config.packages.airnvim;
        };

      flake = {
        # The wrapper lives under `wrappers.airnvim`
        wrappers.airnvim = nixpkgs.lib.modules.importApply ./module.nix inputs;

        nixosModules = {
          airnvim = wrappers.lib.getInstallModule {
            name = "airnvim";
            value = self.wrapperModules.airnvim;
          };
          default = self.nixosModules.airnvim;
        };

        homeModules = {
          airnvim = wrappers.lib.getInstallModule {
            name = "airnvim";
            value = self.wrapperModules.airnvim;
          };
          default = self.homeModules.airnvim;
        };

        overlays = {
          airnvim = final: _: {
            airnvim = self.wrappers.airnvim.wrap { pkgs = final; };
          };
          default = self.overlays.airnvim;
        };
      };
    };
}
