{ pkgs, stdenv, src, ... }:

pkgs.rustPlatform.buildRustPackage {
	pname = "songbook-tui";
	version = "0.2.1";
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
