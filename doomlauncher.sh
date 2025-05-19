#!/bin/bash

# Detect if we are running inside a terminal
if [ -z "$TERM" ] || [ ! -t 1 ]; then
    for term in konsole gnome-terminal xfce4-terminal xterm urxvt alacritty kitty lxterminal mate-terminal terminator; do
        if command -v $term &> /dev/null; then
            exec $term -e bash "$0" "$@"
            exit
        fi
    done
    echo "No supported terminal emulator found. Please run this script from a terminal."
    exit 1
fi

# === Load external config ===
CONFIG_FILE="/etc/doomlauncher/doomlauncher.cfg"
THEME_FILE="/etc/doomlauncher/doomlauncher_theme.rc"

# Known IWADs (lowercase, space-separated list)
KNOWN_IWADS=("doom2.wad" "doom.wad" "plutonia.wad" "tnt.wad" "hexen.wad" "heretic.wad")

# Files to ignore (lowercase, space-separated list)
IGNORE_FILES=("dosbox.exe" "readme.txt" "launch.bat")

# Export dialog theme location
export DIALOGRC="$THEME_FILE"


# Check for 'dialog' installed
if ! command -v dialog &> /dev/null; then
    echo "Error: 'dialog' is not installed."
    echo "Please install it using your package manager:"
    echo "  sudo pacman -S dialog        # Arch"
    echo "  sudo apt install dialog      # Debian/Ubuntu"
    echo "  sudo dnf install dialog      # Fedora"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    dialog --msgbox "Config file '$CONFIG_FILE' not found. Please create it." 10 60
    exit 1
fi

if [ ! -f "$THEME_FILE" ]; then
    dialog --msgbox "Config file '$THEME_FILE' not found. Please create it." 10 60
    exit 1
fi

# Source config variables
source "$CONFIG_FILE"

# === First Time Setup if config values are missing ===

first_time_setup() {
    CONFIG_FILE="/etc/doomlauncher/doomlauncher.cfg"

    while true; do
        # GZDoom command
        GZDOOM_RUNCMD=$(dialog --clear --inputbox \
            "GZDoom run command:\n\nExample: 'gzdoom' or 'flatpak run org.zdoom.GZDoom'" \
            12 80 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && { clear; echo "Setup cancelled."; exit 1; }

        # WADs directory
        DEFAULT_DIR=$(dialog --clear --inputbox \
            "WADs directory:\n\nThis should point to the folder containing your IWADs and PWADs.\nSubdirectories are supported.\n\nExample: ~/Doom/WADs" \
            13 80 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && { clear; echo "Setup cancelled."; exit 1; }

        # Default IWAD
        DEFAULT_IWAD=$(dialog --clear --inputbox \
            "Default IWAD:\n\nThis file is used when launching PWADs.\n\nExample: ~/Doom/WADs/DOOM2.WAD" \
            12 80 3>&1 1>&2 2>&3)

        [ $? -ne 0 ] && { clear; echo "Setup cancelled."; exit 1; }

        # Check for empty values
        if [ -z "$GZDOOM_RUNCMD" ] || [ -z "$DEFAULT_DIR" ] || [ -z "$DEFAULT_IWAD" ]; then
            dialog --msgbox "All fields are required. Please try again." 10 70
            continue
        fi

        # Validate GZDoom command exists
        # Extract the first word of the command for existence check
        firstcmd=$(echo "$GZDOOM_RUNCMD" | awk '{print $1}')
        if ! command -v "$firstcmd" &>/dev/null; then
            dialog --msgbox "Error: Command '$firstcmd' not found in PATH.\nPlease enter a valid GZDoom run command." 10 70
            continue
        fi

        # Validate WADs directory exists
        if [ ! -d "$DEFAULT_DIR" ]; then
            dialog --msgbox "Error: Directory '$DEFAULT_DIR' does not exist.\nPlease enter a valid directory path." 10 70
            continue
        fi

        # Validate Default IWAD file exists
        if [ ! -f "$DEFAULT_IWAD" ]; then
            dialog --msgbox "Error: IWAD file '$DEFAULT_IWAD' does not exist.\nPlease enter a valid file path." 10 70
            continue
        fi

        # Save config
        sudo mkdir -p "$(dirname "$CONFIG_FILE")"
        sudo tee "$CONFIG_FILE" > /dev/null <<EOF
GZDOOM_RUNCMD="$GZDOOM_RUNCMD"
DEFAULT_DIR="$DEFAULT_DIR"
DEFAULT_IWAD="$DEFAULT_IWAD"
EOF

        dialog --msgbox "If you ever want to change these values, edit $CONFIG_FILE" 10 70
        break
    done

    clear
}


# If any required value is missing, run setup
if [ -z "$GZDOOM_RUNCMD" ] || [ -z "$DEFAULT_DIR" ] || [ -z "$DEFAULT_IWAD" ]; then
    first_time_setup
    source /etc/doomlauncher/doomlauncher.cfg
fi

# If script is started with a file argument, launch it directly after checks
if [ $# -ge 1 ]; then
    ARG_FILE="$1"
    if [ ! -f "$ARG_FILE" ]; then
        echo "Error: File '$ARG_FILE' does not exist."
        exit 1
    fi

    FILE_NAME=$(basename "$ARG_FILE")
    FILE_NAME_LOWER=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')

    IS_IWAD=false
    for IWAD in "${KNOWN_IWADS[@]}"; do
        if [[ "$FILE_NAME_LOWER" == "$IWAD" ]]; then
            IS_IWAD=true
            break
        fi
    done

    if $IS_IWAD; then
        $GZDOOM_RUNCMD -iwad "$ARG_FILE"
    else
        $GZDOOM_RUNCMD -file "$ARG_FILE" -iwad "$DEFAULT_IWAD"
    fi

    exit 0
fi

# === Build file list ===
FILE_PAIRS=()
while IFS= read -r file; do
    base=$(basename "$file")
    base_lower=$(echo "$base" | tr '[:upper:]' '[:lower:]')

    skip=false
    for ignore in "${IGNORE_FILES[@]}"; do
        if [[ "$base_lower" == "$ignore" ]]; then
            skip=true
            break
        fi
    done

    if ! $skip; then
        FILE_PAIRS+=("$base::$file")
    fi
done < <(find "$DEFAULT_DIR" -type f)

# Sort filenames
IFS=$'\n' SORTED_PAIRS=($(printf '%s\n' "${FILE_PAIRS[@]}" | sort -f))
unset IFS

MENU_ITEMS=()
for pair in "${SORTED_PAIRS[@]}"; do
    name="${pair%%::*}"
    path="${pair##*::}"
    name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    is_iwad=false
    for iwad in "${KNOWN_IWADS[@]}"; do
        if [[ "$name_lower" == "$iwad" ]]; then
            is_iwad=true
            break
        fi
    done

    if $is_iwad; then
        display_name="$name *"
    else
        display_name="$name"
    fi

    MENU_ITEMS+=("$display_name" "$path")
done

CHOICE=$(dialog --clear \
    --title "Doomlauncher" \
    --extra-button \
    --extra-label "Custom Path" \
    --ok-label "OK" \
    --cancel-label "Cancel" \
    --menu "Select a file to run with GZDoom:" 20 100 15 \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3)

RET=$?

clear

if [ $RET -eq 1 ]; then
    echo "Cancelled."
    exit 1
elif [ $RET -eq 3 ]; then
    FILE_TO_RUN=$(dialog --clear \
        --title "Custom File Path" \
        --inputbox "Enter the full path to your WAD/PK3 file:" 10 80 \
        3>&1 1>&2 2>&3)

    clear

    if [ -z "$FILE_TO_RUN" ]; then
        echo "No path entered. Exiting."
        exit 1
    fi
else
    for ((i=1; i<${#MENU_ITEMS[@]}; i+=2)); do
        if [[ "${MENU_ITEMS[i-1]}" == "$CHOICE" ]]; then
            FILE_TO_RUN="${MENU_ITEMS[i]}"
            break
        fi
    done
fi

FILE_NAME=$(basename "$FILE_TO_RUN")
FILE_NAME_LOWER=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')

IS_IWAD=false
for IWAD in "${KNOWN_IWADS[@]}"; do
    if [[ "$FILE_NAME_LOWER" == "$IWAD" ]]; then
        IS_IWAD=true
        break
    fi
done

if $IS_IWAD; then
    $GZDOOM_RUNCMD -iwad "$FILE_TO_RUN"
else
    $GZDOOM_RUNCMD -file "$FILE_TO_RUN" -iwad "$DEFAULT_IWAD"
fi
