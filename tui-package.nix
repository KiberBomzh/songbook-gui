{ pkgs, stdenv, src, ... }:

let cargoToml = builtins.fromTOML (builtins.readFile "${src}/Cargo.toml");
in pkgs.rustPlatform.buildRustPackage {
	pname = "songbook-tui";
	version = cargoToml.package.version;
	src = src;
	cargoLock.lockFile = "${src}/Cargo.lock";

	buildInputs = with pkgs; [
		glib
		gtk3
	];

	nativeBuildInputs = with pkgs; [
		pkg-config
	];

	buildPhase = ''cargo build --release --features "tui from_url"'';
	installPhase = ''
		mkdir -p $out/bin
		cp target/release/songbook $out/bin/
	'';
}
