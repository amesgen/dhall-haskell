let pinned = import ./nix/pinnedNixpkgs.nix;

in { src ? { rev = ""; }
, nixpkgs ? pinned.nixpkgs
, nixpkgsStaticLinux ? pinned.nixpkgsStaticLinux
}:

let
  callShared = args:
    import ./nix/shared.nix ({ inherit nixpkgs nixpkgsStaticLinux; } // args);

  shared_8_2_2 = callShared { compiler = "ghc822"; };

  shared_8_6_1 = callShared { compiler = "ghc861"; };

  shared_ghcjs = callShared { compiler = "ghcjs"; };

  shared = callShared { };

  shared_linux = callShared { system = "x86_64-linux"; };

  coverage = callShared { coverage = true; };

in
  { dhall = shared.aggregate
      { name = "dhall";

        constituents = [
          # Verify that the packages build against the oldest supported version
          # of the compiler
          shared_8_2_2.dhall
          shared_8_2_2.dhall-bash
          shared_8_2_2.dhall-json
          # `dhall-nix` → `hnix` → `4.11 <= base` → `8.4.1 <= ghc`
          # shared_8_2_2.dhall-nix
          # `HsYAML-aeson` requires Cabal >= 2.2, which implies GHC 8.4 or newer
          # shared_8_2_2.dhall-yaml
          # `base-noprelude` depends on a specific version of `base`
          # shared_8_2_2.dhall-lsp-server

          # Verify that the packages build against the latest supported version
          # of the compiler
          shared_8_6_1.dhall
          shared_8_6_1.dhall-bash
          shared_8_6_1.dhall-json
          shared_8_6_1.dhall-yaml
          # `base-noprelude` depends on a specific version of `base`
          # shared_8_6_1.dhall-lsp-server
          # `hnix` depends on `unix-2.7.*` and doesn't work with GHC 8.6
          # shared_8_6_1.dhall-nix

          shared_ghcjs.dhall-try

          # However, we still use GHC 8.4.3 to build the distributed tarballs
          # due to a bug in GHC 8.6.1.  See:
          #
          # https://ghc.haskell.org/trac/ghc/ticket/15696
          shared.tarball-dhall
          shared.tarball-dhall-bash
          shared.tarball-dhall-json
          shared.tarball-dhall-lsp-server
          shared.tarball-dhall-nix
          shared.tarball-dhall-yaml

          # This is the only `dhall` build that runs the test suite
          coverage.dhall
          coverage.dhall-json
          coverage.dhall-yaml

          # Check that the package builds with HTTP support compiled out
          shared.dhall-no-http

          (shared.trivial src.rev)
        ];
      };

    "coverage-dhall" = coverage.dhall;

    inherit (shared)
      tarball-dhall
      tarball-dhall-bash
      tarball-dhall-json
      tarball-dhall-lsp-server
      tarball-dhall-nix
      tarball-dhall-yaml
    ;

    linux-dhall            = shared_linux.possibly-static.dhall;
    linux-dhall-bash       = shared_linux.possibly-static.dhall-bash;
    linux-dhall-json       = shared_linux.possibly-static.dhall-json;
    linux-dhall-lsp-server = shared_linux.possibly-static.dhall-lsp-server;
    linux-dhall-nix        = shared_linux.possibly-static.dhall-nix;
    linux-dhall-yaml       = shared_linux.possibly-static.dhall-yaml;

    inherit (shared_linux)
      image-dhall
      image-dhall-bash
      image-dhall-json
      image-dhall-lsp-server
      image-dhall-nix
      image-dhall-yaml
    ;
  }
