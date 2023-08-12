{
  system,
  pkgs,
  hdx-inputs,
}: let
  inherit (pkgs) lib stdenv;
  inherit (lib) optionalAttrs elem;

  hdx-config = {
    amaranth.enable = true;
    yosys.enable = true;
    nextpnr = {
      enable = true;
      archs = ["generic" "ice40" "ecp5"];
    };
    symbiyosys = {
      enable = true;
      solvers = ["yices" "z3"];
    };
  };

  # I feel iffy about not mixing in pkgs here too -- especially given we
  # override Boost and it'd be easy to forget to include it in a module's
  # args list and have the pkgs one accidentally used in a "with pkgs; [
  # ... ]" section --, but it was causing me bugs when icestorm/trellis
  # were falling through to base packages while I was trying to work out a
  # nice way to conditionally build.  Maybe later when I know this stuff
  # better.
  callPackage = lib.callPackageWith env;
  env =
    {
      inherit system pkgs lib stdenv;
      inherit hdx-inputs hdx-config;
      inherit ours;

      python = import ./pkgs/python.nix {python = pkgs.python311;};
      boost = callPackage ./pkgs/boost.nix {};

      leaveDotGitWorkaround = ''
        # Workaround for NixOS/nixpkgs#8567.
        pushd source
        git init
        git config user.email charlotte@example.com
        git config user.name Charlotte
        git add -A .
        git commit -m "leaveDotGit workaround"
        popd
      '';
      devCheckHook = folders: cmd:
        lib.concatStringsSep "\n" (map (folder: ''
            if ! test -d "${folder}"; then
              echo "ERROR: $(pwd) doesn't look like hdx root? (or no '${folder}' found)"
              echo "'${cmd}' only works when executed with hdx-like cwd, otherwise we"
              echo "can't set up correctly."
              exit 1
            fi
          '')
          folders);
    }
    // ours;

  nextpnrArchs =
    {}
    // optionalAttrs (elem "ice40" hdx-config.nextpnr.archs) {icestorm = callPackage ./pkgs/icestorm.nix {};}
    // optionalAttrs (elem "ecp5" hdx-config.nextpnr.archs) {trellis = callPackage ./pkgs/trellis.nix {};};

  ours =
    {}
    // optionalAttrs (hdx-config.amaranth.enable) {
      amaranth = callPackage ./pkgs/amaranth.nix {};
      amaranth-boards = callPackage ./pkgs/amaranth-boards.nix {};
    }
    // optionalAttrs (hdx-config.yosys.enable) {yosys = callPackage ./pkgs/yosys.nix {};}
    // optionalAttrs (hdx-config.nextpnr.enable) ({nextpnr = callPackage ./pkgs/nextpnr.nix {inherit nextpnrArchs;};} // nextpnrArchs)
    // optionalAttrs (hdx-config.symbiyosys.enable) (
      {symbiyosys = callPackage ./pkgs/symbiyosys.nix {};}
      // optionalAttrs (elem "z3" hdx-config.symbiyosys.solvers) {z3 = callPackage ./pkgs/z3.nix {};}
      // optionalAttrs (elem "yices" hdx-config.symbiyosys.solvers) {yices = callPackage ./pkgs/yices.nix {};}
    );
in
  stdenv.mkDerivation ({
      name = "hdx";

      dontUnpack = true;

      propagatedBuildInputs =
        [
          env.python
        ]
        ++ builtins.attrValues ours;

      passthru = env;
    }
    // optionalAttrs (hdx-config.amaranth.enable) rec {
      buildInputs = [pkgs.makeWrapper];

      AMARANTH_USE_YOSYS = ours.amaranth.AMARANTH_USE_YOSYS;

      installPhase = ''
        for b in ${env.python}/bin/*; do
          makeWrapper "$b" "$out/bin/$(basename "$b")" --inherit-argv0 --set AMARANTH_USE_YOSYS ${AMARANTH_USE_YOSYS}
        done
      '';
    })
