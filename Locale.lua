ComfyCastBar = ComfyCastBar or {}
local A = ComfyCastBar

local de = GetLocale and GetLocale() == "deDE"

local EN = {
    GENERAL="General", UNITS="Bars", STYLE="Style", PROFILES="Profiles", INFO="Info",
    ENABLE="Enable ComfyCastBar", TEST="Test mode", UNLOCK="Unlock bars", LOCK="Lock bars",
    HIDE_BLIZZARD="Hide Blizzard player cast bar", LATENCY="Show player latency zone",
    PLAYER="Player", TARGET="Target", FOCUS="Focus", PET="Pet",
    WIDTH="Width", HEIGHT="Height", FONT_SIZE="Font size", SHOW_ICON="Show spell icon",
    SHOW_NAME="Show spell name", SHOW_TIME="Show remaining time",
    CAST_COLOR="Cast color", CHANNEL_COLOR="Channel color", UNINTERRUPTIBLE_COLOR="Not interruptible color",
    BACKGROUND_COLOR="Background color", COLOR_HINT="Use 6-digit RGB hex values, for example FFB300.",
    RESET_POSITIONS="Reset bar positions", PRESET_MINIMAL="Minimal", PRESET_STANDARD="Standard", PRESET_PVP="PvP",
    PROFILES_HINT="Every character has its own profile. Account and custom profiles can also be selected.",
    ACTIVE_PROFILE="Active profile", ACCOUNT_PROFILE="Account", CHARACTER_PROFILE="Character",
    CUSTOM_PROFILE="Custom profile", CREATE="Create", DELETE="Delete custom", RESET_PROFILE="Reset profile",
    INFO_NOTICE="ComfyCastBar changes the UI only. It does not automate gameplay.",
    INFO_COMMANDS="/ccb, /ccb test, /ccb unlock, /ccb lock, /ccb reset",
    STATUS_CAST="Casting", STATUS_CHANNEL="Channeling", TEST_SPELL="Test Spell",
    COMPAT_OK="Compatible", COMPAT_WARN="Interface differs from tested target",
    LOADED="Loaded.", LOCKED_COMBAT="Bars cannot be moved during combat.",
}

local DE = {
    GENERAL="Allgemein", UNITS="Leisten", STYLE="Stil", PROFILES="Profile", INFO="Info",
    ENABLE="ComfyCastBar aktivieren", TEST="Testmodus", UNLOCK="Leisten entsperren", LOCK="Leisten sperren",
    HIDE_BLIZZARD="Blizzard-Spieler-Castbar ausblenden", LATENCY="Spieler-Latenzbereich anzeigen",
    PLAYER="Spieler", TARGET="Ziel", FOCUS="Fokus", PET="Begleiter",
    WIDTH="Breite", HEIGHT="Höhe", FONT_SIZE="Schriftgröße", SHOW_ICON="Zaubericon anzeigen",
    SHOW_NAME="Zaubername anzeigen", SHOW_TIME="Restzeit anzeigen",
    CAST_COLOR="Farbe Zauber", CHANNEL_COLOR="Farbe Kanalisieren", UNINTERRUPTIBLE_COLOR="Farbe nicht unterbrechbar",
    BACKGROUND_COLOR="Hintergrundfarbe", COLOR_HINT="6-stellige RGB-Hexwerte verwenden, z. B. FFB300.",
    RESET_POSITIONS="Leistenpositionen zurücksetzen", PRESET_MINIMAL="Minimal", PRESET_STANDARD="Standard", PRESET_PVP="PvP",
    PROFILES_HINT="Jeder Charakter hat ein eigenes Profil. Account- und eigene Profile können ebenfalls gewählt werden.",
    ACTIVE_PROFILE="Aktives Profil", ACCOUNT_PROFILE="Account", CHARACTER_PROFILE="Charakter",
    CUSTOM_PROFILE="Eigenes Profil", CREATE="Erstellen", DELETE="Eigenes löschen", RESET_PROFILE="Profil zurücksetzen",
    INFO_NOTICE="ComfyCastBar verändert nur die Benutzeroberfläche und automatisiert keine Spielaktionen.",
    INFO_COMMANDS="/ccb, /ccb test, /ccb unlock, /ccb lock, /ccb reset",
    STATUS_CAST="Wirkt", STATUS_CHANNEL="Kanalisiert", TEST_SPELL="Testzauber",
    COMPAT_OK="Kompatibel", COMPAT_WARN="Interface weicht vom getesteten Ziel ab",
    LOADED="Geladen.", LOCKED_COMBAT="Leisten können im Kampf nicht verschoben werden.",
}

local STRINGS = de and DE or EN
function A:T(key) return STRINGS[key] or EN[key] or key end
