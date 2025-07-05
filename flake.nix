{
  description = "Sparkzky's NixOS Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    r3playx.url = "github:EndCredits/R3PLAYX-nix/master";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    rust-overlay,
    vscode-server,
    r3playx,
    ...
  }@inputs:
  let
    system = "x86_64-linux";
    overlays = [ (import rust-overlay) ];
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit unstable r3playx;
      };
      modules = [
        # Basic system configuration
        ./configuration.nix

        # Configure nixpkgs
        {
          nixpkgs = {
            overlays = overlays;
            config = { allowUnfree = true; };
          };
        }

        # Home Manager configuration
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit unstable r3playx; };
            users.sparkzky = import ./home.nix;
#             backupFileExtension = "backup";
          };
        }

        # VSCode server
        vscode-server.nixosModules.default
        { services.vscode-server.enable = true; }
      ];
    };
  };
}
