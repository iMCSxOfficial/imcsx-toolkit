#!/usr/bin/env bash
# =============================================================================
#  iMCSx Security Toolkit — Installation en ligne (depuis GitHub)
#  Copyright (c) 2026 iMCSx. Tous droits reserves.
#
#  Installe iMCSx en une commande, en telechargeant le binaire depuis la
#  derniere Release GitHub. A publier sur ton depot ; le client lance :
#
#      curl -fsSL https://raw.githubusercontent.com/<REPO>/main/web-install.sh | bash
#
#  (Remplace <REPO> par ton depot, ou exporte IMCSX_REPO avant de lancer.)
# =============================================================================
set -e
REPO="${IMCSX_REPO:-iMCSxOfficial/imcsx-toolkit}"
BIN_URL="https://github.com/$REPO/releases/latest/download/imcsx"
LOGO_URL="https://raw.githubusercontent.com/$REPO/main/assets/imcsx-logo.png"

BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons"
APP_DIR="$HOME/.local/share/applications"
LAUNCH="$BIN_DIR/imcsx-launch"
DESKTOP="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[ -d "$DESKTOP" ] || DESKTOP="$HOME/Bureau"
[ -d "$DESKTOP" ] || DESKTOP="$HOME/Desktop"
[ -d "$DESKTOP" ] || DESKTOP="$HOME"

command -v curl >/dev/null || { echo "curl est requis (sudo apt install curl)"; exit 1; }
mkdir -p "$BIN_DIR" "$ICON_DIR" "$APP_DIR"

echo "[*] Téléchargement d'iMCSx Toolkit depuis GitHub ($REPO)..."
curl -fL "$BIN_URL" -o "$BIN_DIR/imcsx"
chmod +x "$BIN_DIR/imcsx"
curl -fsL "$LOGO_URL" -o "$ICON_DIR/imcsx.png" 2>/dev/null || true

cat > "$LAUNCH" <<'LAUNCHER'
#!/usr/bin/env bash
BIN="$HOME/.local/bin/imcsx"
_run(){ "$BIN"; echo; read -n1 -r -p "[iMCSx] Appuie sur une touche pour fermer..."; }
[ -t 1 ] && { _run; exit; }
for T in x-terminal-emulator qterminal xfce4-terminal konsole xterm lxterminal; do
  command -v "$T" >/dev/null 2>&1 && exec "$T" -e "$HOME/.local/bin/imcsx-launch"
done
command -v gnome-terminal >/dev/null 2>&1 && exec gnome-terminal -- "$HOME/.local/bin/imcsx-launch"
_run
LAUNCHER
chmod +x "$LAUNCH"

cat > "$BIN_DIR/imcsx-uninstall" <<'UNINST'
#!/usr/bin/env bash
"$HOME/.local/bin/imcsx" --no-banner checkin --uninstall >/dev/null 2>&1 || true
D="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[ -d "$D" ] || D="$HOME/Bureau"; [ -d "$D" ] || D="$HOME/Desktop"
rm -f "$HOME/.local/bin/imcsx" "$HOME/.local/bin/imcsx-launch" \
      "$HOME/.local/share/icons/imcsx.png" \
      "$HOME/.local/share/applications/imcsx.desktop" \
      "$D/iMCSx Toolkit.desktop"
rm -rf "$HOME/.config/imcsx" "$HOME/.cache/imcsx"
echo "[+] iMCSx a ete desinstalle."
rm -f "$HOME/.local/bin/imcsx-uninstall"
UNINST
chmod +x "$BIN_DIR/imcsx-uninstall"

ENTRY="[Desktop Entry]
Version=1.0
Type=Application
Name=iMCSx Toolkit
GenericName=Security Toolkit
Comment=iMCSx Security Toolkit
Exec=$LAUNCH
Icon=$ICON_DIR/imcsx.png
Terminal=false
Categories=Security;System;
StartupNotify=true
"
printf '%s' "$ENTRY" > "$APP_DIR/imcsx.desktop"; chmod +x "$APP_DIR/imcsx.desktop"
printf '%s' "$ENTRY" > "$DESKTOP/iMCSx Toolkit.desktop"; chmod +x "$DESKTOP/iMCSx Toolkit.desktop"
gio set "$DESKTOP/iMCSx Toolkit.desktop" metadata::trusted true 2>/dev/null || true
update-desktop-database "$APP_DIR" 2>/dev/null || true

# Enregistre immediatement ce PC aupres de l'editeur (remonte dans l'Admin).
"$BIN_DIR/imcsx" --no-banner checkin >/dev/null 2>&1 || true

echo "[+] Installé ! Raccourci « iMCSx Toolkit » sur le bureau."
echo "    ID machine : $("$BIN_DIR/imcsx" --no-banner license --machine-id 2>/dev/null | tail -1)"
echo "    Activer PRO : imcsx license --install ta_licence.key"
echo "    Licence PRO : iamimcsx@proton.me"
echo "    Désinstaller : ~/.local/bin/imcsx-uninstall"
