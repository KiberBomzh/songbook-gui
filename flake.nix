{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          abiVersions = [ "armeabi-v7a" "arm64-v8a" "x86_64" ];
          buildToolsVersions = [ "35.0.0" ];
		  cmakeVersions = [ "3.22.1" ];
          platformVersions = [ "33" "34" "35" "36" ];
		  ndkVersion = "28.2.13676358";
		  includeNDK = true;
          includeEmulator = false;
          includeSystemImages = false;
          includeSources = false;
        };
        androidSdk = androidComposition.androidsdk;

		androidEnv = {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
		};
        
      in {
        devShells = {
			android = with pkgs; mkShell {
			  inherit (androidEnv) ANDROID_SDK_ROOT ANDROID_HOME;
			  JAVA_HOME = "${jdk}";

			  buildInputs = [
				flutter
				rustup
				androidSdk
				jdk21
				gradle
			  ];
          
			  shellHook = ''
				export HOME="$PWD/.nix-cache"

				export PUB_CACHE="$HOME/.pub-cache"
				export GRADLE_USER_HOME="$HOME/.gradle"
				export CARGO_HOME="$HOME/.cargo"
				export RUSTUP_HOME="$HOME/.rustup"
			  '';
			};

			linux = with pkgs; mkShell {
			  buildInputs = [
				flutter
				rustup

				libGL

				mesa-demos
			  ];

			  shellHook = ''
				export HOME="$PWD/.nix-cache"

				export PUB_CACHE="$HOME/.pub-cache"
				export CARGO_HOME="$HOME/.cargo"
				export RUSTUP_HOME="$HOME/.rustup"

				export LD_LIBRARY_PATH="$PWD/build/linux/x64/debug/bundle/lib:$LD_LIBRARY_PATH"
				export LD_LIBRARY_PATH="$PWD/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"
			  '';
			};

			default = self.devShells.${system}.android;
		};

		devShell = self.devShells.${system}.default;
      }
    );
}
