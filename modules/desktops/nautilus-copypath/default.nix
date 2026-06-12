{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "nautilus-copypath";
  version = "0-unstable-2025-bbfa58c";

  src = ./.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 nautilus-copypath.py \
      "$out/share/nautilus-python/extensions/nautilus-copypath.py"
    runHook postInstall
  '';

  meta = {
    description = "Nautilus extension to copy file/directory paths from the right-click menu";
    homepage = "https://git.sr.ht/~ronenk17/nautilus-copypath";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
