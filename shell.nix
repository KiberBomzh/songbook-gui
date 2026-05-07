let pkgs = import (fetchTarball("https://github.com/NixOS/nixpkgs/tarball/25.11")) {};
in pkgs.callPackage (
	{
		mkShell,
		cargo,
		rustc,
		pkg-config,
	}:
	mkShell {
		strictDeps = true;
		nativeBuildInputs = [
			cargo
			rustc
			pkg-config
		];
		buildInputs = with pkgs; [ 
			glib
			gtk3
		];
	}
) { }
