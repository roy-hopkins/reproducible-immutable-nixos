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
            src = ./bin;  # Point to the directory containing all files
            
            nativeBuildInputs = [ pkgs.patchelf ];
            buildInputs = [ pkgs.curl ];
            
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/lib
              
              # Copy the executable
              install -Dm755 $src/CVMAttest $out/bin/CVMAttest
              
              # Copy the shared library
              install -Dm644 $src/libedge-cc-base-attestation-sdk.so $out/lib/libedge-cc-base-attestation-sdk.so
              
              # Patch the binary to find libraries
              echo "Patching CVMAttest binary..."
              patchelf --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.curl ]}:$out/lib" $out/bin/CVMAttest || echo "patchelf failed, continuing..."
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
