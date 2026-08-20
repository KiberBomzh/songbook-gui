{ pkgs, stdenv, src, ... }:

let
	importYaml = file: let
		yamlJSON = pkgs.runCommand "import-yaml" {
			buildInputs = [ pkgs.yj ];
		} "yj -yj < ${file} > $out";
	in pkgs.lib.importJSON yamlJSON;

	rustLib = pkgs.rustPlatform.buildRustPackage {
		pname = "rust_lib_songbook";
		version = "0.1.0";
		src = src;
		cargoLock.lockFile = "${src}/Cargo.lock";
		doCheck = false;

		buildPhase = "cargo build -p rust_lib_songbook --release";
		installPhase = ''
			mkdir -p $out/lib
			cp target/release/librust_lib_songbook.so $out/lib/
		'';
	};

	flutterBuildInputs = with pkgs; [
		libGL
		mesa
		gtk3

		rustLib
	];

in 
	pkgs.flutter.buildFlutterApplication {
		pname = "songbook-gui";
		version = "2.1.1";
		src = src;
		
		pubspecLock = importYaml "${src}/pubspec.lock";

		buildInputs = flutterBuildInputs;
		nativeBuildInputs = with pkgs; [
			jdk21
		];

		postConfigure = ''
			sed -i '/rust_lib_songbook:/d' pubspec.yaml
			sed -i '/path: rust_builder/d' pubspec.yaml
		'';

		postInstall = ''
			cp ${rustLib}/lib/librust_lib_songbook.so $out/app/songbook-gui/lib/

			mv $out/bin/songbook $out/bin/songbook-gui

			wrapProgram $out/app/songbook-gui/songbook \
				--set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath flutterBuildInputs}" \
				--set LIBGL_DRIVERS_PATH "${pkgs.mesa}/lib/dri}" \
				--set GTK_PIXBUF_MODULE_FILE "${pkgs.gdk-pixbuf.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"


			mkdir -p $out/share/icons
			cp "${src}/assets/icon.png" $out/share/icons/icon.png

			mkdir -p $out/share/applications
			sed 's/Exec=songbook/Exec=songbook-gui/' ${src}/linux/AppDir/songbook.desktop > $out/share/applications/songbook.desktop
		'';
	}
