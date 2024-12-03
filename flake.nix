{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    naersk.url = "github:nix-community/naersk";

    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.git-hooks-nix.flakeModule
      ];

      perSystem =
        { pkgs, config, ... }:
        let
          inherit (builtins) map listToAttrs genList;
          naersk = pkgs.callPackage inputs.naersk { };
        in
        {
          packages =
            {
              default = naersk.buildPackage { src = ./.; };
            }
            // listToAttrs (
              map (name: {
                inherit name;
                value = naersk.buildPackage {
                  src = ./.;
                  pname = name;
                };
              }) (genList (x: "day${toString (x + 1)}") 31)
            );

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              rustc
              cargo
            ];
            buildInputs = [ pkgs.nil ];
            shellHook = config.pre-commit.installationScript;
          };

          formatter = pkgs.nixfmt-rfc-style;

          pre-commit.settings.hooks = {
            nixfmt-rfc-style.enable = true;
            deadnix.enable = true;
            trim-trailing-whitespace.enable = true;
          };
        };
    };
}
