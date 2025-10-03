{
  description = "Reproducible and Immutable NixOS Images";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
      ];
      perSystem = { config, pkgs, ... }: {
        packages = {
          qemu-image = pkgs.callPackage ./image {
            platform = "qemu";
            cvmattest = config.packages.cvmattest;
          };
          hyperv-image = pkgs.callPackage ./image/hyperv.nix {
            platform = "hyperv";
            cvmattest = config.packages.cvmattest;
          };
          #boot-uefi-qemu = pkgs.callPackage ./utils/boot-uefi-qemu.nix { };
          
                    # Custom binary package
          cvmattest = pkgs.stdenv.mkDerivation {
            pname = "cvmattest";
            version = "1.0";
            src = ./bin;

            nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.patchelf ];
            buildInputs = [ 
              pkgs.curl 
              pkgs.stdenv.cc.cc 
              pkgs.tpm2-tss
              pkgs.openssl_3
              pkgs.libuuid
            ];

            # We copy files; autoPatchelf runs in fixupPhase and will patch ELF RPATHs
            installPhase = ''
              runHook preInstall
              install -Dm755 $src/CVMAttest $out/bin/CVMAttest
              install -Dm644 $src/libedge-cc-base-attestation-sdk.so \
                $out/lib/libedge-cc-base-attestation-sdk.so
              runHook postInstall
            '';

            # Ensure interpreter & final RPATH explicitly include our lib dir + dependencies
            postFixup = ''
              echo "Final patchelf adjustments for CVMAttest"
              interp="$(cat $NIX_CC/nix-support/dynamic-linker)"
              patchelf --set-interpreter "$interp" $out/bin/CVMAttest || true
              patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.curl pkgs.stdenv.cc.cc ]}:$out/lib" \
                $out/bin/CVMAttest || true
            '';

            meta = with pkgs.lib; {
              description = "CVM Attestation test tool";
              platforms = platforms.linux;
            };
          };
        };
      };
    };
}
