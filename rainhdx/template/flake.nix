{
  description = "rainhdx project template";

  inputs = {
    hdx.url = github:charlottia/hdx;
    nixpkgs.follows = "hdx/nixpkgs";
    flake-utils.follows = "hdx/flake-utils";
  };

  outputs = inputs @ {
    self,
    hdx,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      inherit (hdx.packages.${system}) rainhdx;
      inherit (rainhdx) python;
    in rec {
      formatter = pkgs.alejandra;

      packages.default = rainhdx.buildProject {
        name = "proj";
        src = ./.;

        nativeBuildInputs = [
          python.pkgs.pypng
        ];
      };

      devShells = packages.default.devShells;
    });
}
