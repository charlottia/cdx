# [hdx](https://hrzn.ee/kivikakk/hdx)

hdx packages [Amaranth] (+ [`-boards`][amaranth-boards],
[`-stdio`][amaranth-stdio]) and [Yosys] on Nix. These are already available in
nixpkgs, but hdx also lets you use on-disk checkouts for Amaranth and/or Yosys.
This lets you test your own changes (or debug crashes) in the context of your
own project on Nix.

It also ships with [Rain](#rain), a small framework for building projects with
Amaranth. A Rain project also has a devShell for using an on-disk Yosys
checkout. (Planned: Amaranth also, depending on how much work it is to get two
editable checkouts at once.)

[Amaranth]: https://github.com/amaranth-lang/amaranth
[amaranth-boards]: https://github.com/amaranth-lang/amaranth-boards
[amaranth-stdio]: https://github.com/amaranth-lang/amaranth-stdio
[Yosys]: https://github.com/YosysHQ/yosys


## Usage

* `nix develop git+https://hrzn.ee/kivikakk/hdx`

  This is the default mode of operation. Yosys and Amaranth are built and added
  to `PATH`.

  Amaranth is configured to use the Yosys built by hdx, and not its built-in
  one.

* `nix develop git+https://hrzn.ee/kivikakk/hdx#amaranth`

  An Amaranth checkout in `./` or `./amaranth/` is expected, and installed in
  editable mode. Yosys is still built, added to `PATH`, and used by your
  Amaranth checkout as usual.

* `nix develop git+https://hrzn.ee/kivikakk/hdx#amaranth-yosys`

  An Amaranth checkout is expected at `./amaranth/`, and a Yosys checkout is
  expected at `./yosys`. Amaranth is installed in editable mode. Yosys is
  configured to be compiled and installed to `./yosys/hdx-out/`, and `PATH` has
  the output directory's `bin` subdirectory prepended. You'll need to actually
  `make install` Yosys at least once for this mode to function, including any
  use of Amaranth that depends on Yosys.

* <a name="your-flake-nix" id="your-flake-nix"></a>Your project's `flake.nix`

  ```nix
  {
    inputs.hdx.url = git+https://hrzn.ee/kivikakk/hdx;

    outputs = {
      self,
      nixpkgs,
      flake-utils,
      hdx,
    }:
      flake-utils.lib.eachDefaultSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            hdx.packages.${system}.default
          ];
        };
      });
  }
  ```

  * Want to specify a different version of a dependency? WE HAVE A TOOL FOR
    THAT:

    ```nix
    inputs = {
      hdx.url = git+https://hrzn.ee/kivikakk/hdx;
      hdx.inputs.amaranth.url = git+https://codeberg.org/lilnyonker/amaranth?ref=my-feature-branch;
    };
    ```


## Rain

To get started, you can use the included flake template:

```shell
mkdir nyonkomatic
cd nyonkomatic
nix flake init -t git+https://hrzn.ee/kivikakk/hdx#rainhdx
```

Then you can enter a development environment with `nix develop`. Try `python -m
proj` to see what the default CLI options are.

There's a workable example at <https://hrzn.ee/kivikakk/ledmatriks> to check
out.

If you want to use your own on-disk checkout of Yosys with your Rain project,
`nix develop .#yosys` will expect a Yosys checkout at `./yosys` or `../yosys`.


## Background

hdx originally reproduced the entire setup described in [Installing an HDL
toolchain from source] in Nix, and mostly served as a way for me to learn Nix.
It's since been refined in its scope.

[Installing an HDL toolchain from source]: https://lottia.net/notes/0001-hdl-toolchain-source.html
