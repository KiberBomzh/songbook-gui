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


			frb_src = pkgs.fetchFromGitHub {
				owner = "fzyzcjy";
				repo = "flutter_rust_bridge";
				rev = "62b9330ed2f900535e34d8443ff82dc54070579a";
				hash = "sha256-8lLHnJ3IWDZHsj444Gvl0BN+wRlc5JeQfdOQi0QG1Wg=";
				fetchSubmodules = true;
			};

			flutter_rust_bridge_codegen = pkgs.rustPlatform.buildRustPackage {
				name = "flutter_rust_bridge_codegen";
				version = "2.12.0";
				src = frb_src;

				cargoToml = "frb_codegen/Cargo.toml";
				cargoHash = "sha256-R6Brxb8OGkInAH/+GPoxc2f/bSWcsWP3aUMh1VrKBuc=";


				checkFlags = [
					# skipping these tests, as they rely on a specific directory structure, which nix messes up. We can't patch the tests.
					"--skip=library::codegen::config::internal_config_parser::tests::test_parse_rust_output_faulty"
					"--skip=library::codegen::config::internal_config_parser::tests::test_parse_single_rust_input"
					"--skip=library::codegen::config::internal_config_parser::tests::test_parse_wildcard_rust_input"
					"--skip=library::codegen::generator::api_dart::tests::test_functions"
					"--skip=library::codegen::generator::api_dart::tests::test_simple"
					"--skip=library::codegen::parser::tests::test_error_non_opaque_mut"
					"--skip=library::codegen::parser::tests::test_generics"
					"--skip=library::codegen::parser::tests::test_methods"
					"--skip=library::codegen::parser::tests::test_multi_input_file"
					"--skip=library::codegen::parser::tests::test_non_qualified_names"
					"--skip=library::codegen::parser::tests::test_qualified_names"
					"--skip=library::codegen::parser::tests::test_simple"
					"--skip=library::codegen::parser::tests::test_unused_struct_enum"
					"--skip=library::codegen::parser::tests::test_use_type_in_another_file"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_mode_config_file"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_mode_from_naive_generate_command_args"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_mode_config_file_faulty_file"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_mode_from_files_auto_pubspec_yaml"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_mode_from_files_auto_flutter_rust_bridge_yaml"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_mode_from_files_auto_pubspec_yaml_faulty"
					"--skip=binary::commands_parser::tests::test_compute_codegen_config_from_both_file_and_command_line"
					"--skip=tests::test_execute_generate_on_frb_example_dart_minimal"
					"--skip=tests::test_execute_generate_on_frb_example_pure_dart"
					"--skip=library::utils::logs::configure_opinionated_logging"
				];
			};

			baseShellHook = ''
				OLD_HOME=$HOME
				export HOME="$PWD/.nix-cache"

				export PUB_CACHE="$HOME/.pub-cache"
				export CARGO_HOME="$HOME/.cargo"
				export RUSTUP_HOME="$HOME/.rustup"

				# nvim settings symlinks
				ln -sf $OLD_HOME/.config/nvim $HOME/.config/nvim
				ln -sf $OLD_HOME/.local/share/nvim $HOME/.local/share/nvim
				ln -sf $OLD_HOME/.cache/nvim $HOME/.cache/nvim
			'';

		in {
			packages = {
				default = self.packages.${system}.gui;

				gui = pkgs.callPackage ./gui-package.nix { src = self; };
				tui = pkgs.callPackage ./tui-package.nix { src = "${self}/songbook-library"; };
			};

			devShells = {
				android = with pkgs; mkShell {
					inherit (androidEnv) ANDROID_SDK_ROOT ANDROID_HOME;
					JAVA_HOME = "${jdk}";

					buildInputs = [
						flutter
						flutter_rust_bridge_codegen
						rustup
						androidSdk
						jdk21
						gradle
					];

					shellHook = ''
						${baseShellHook}

						export GRADLE_USER_HOME="$HOME/.gradle"
					'';
				};

				linux = let
					runtimeDeps = with pkgs; [
						libGL
						stdenv.cc.cc.lib
						gtk3
					];
				in with pkgs; mkShell {
					buildInputs = [
						flutter
						flutter_rust_bridge_codegen
						rustup
					] ++ runtimeDeps;

					shellHook = ''
						${baseShellHook}

						export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeDeps}:$LD_LIBRARY_PATH"

						export LD_LIBRARY_PATH="$PWD/build/linux/x64/debug/bundle/lib:$LD_LIBRARY_PATH"
						export LD_LIBRARY_PATH="$PWD/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"


						export FLUTTER_ENGINE_DISABLE_AOT=true
					'';
				};

				default = let
					runtimeDeps = with pkgs; [
						libGL
						stdenv.cc.cc.lib
						gtk3
					];
				in with pkgs; mkShell {
					inherit (androidEnv) ANDROID_SDK_ROOT ANDROID_HOME;
					JAVA_HOME = "${jdk}";

					buildInputs = [
						flutter
						flutter_rust_bridge_codegen
						rustup
						androidSdk
						jdk21
						gradle
					] ++ runtimeDeps;

					shellHook = ''
						${baseShellHook}

						export GRADLE_USER_HOME="$HOME/.gradle"


						export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeDeps}:$LD_LIBRARY_PATH"

						export LD_LIBRARY_PATH="$PWD/build/linux/x64/debug/bundle/lib:$LD_LIBRARY_PATH"
						export LD_LIBRARY_PATH="$PWD/build/linux/x64/release/bundle/lib:$LD_LIBRARY_PATH"


						export FLUTTER_ENGINE_DISABLE_AOT=true
					'';
				};
			};
		}
	);
}
