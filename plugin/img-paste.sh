#!/bin/bash
VERSION="img-paste.sh ver 0.2.6 (01/20/2024)"
set -eu -o pipefail

function usage() {
    echo "
Save the image in the clipboard to a file.

Usage:
    $(basename $0) <output-file>
"
    exit 1
}

function config() {
    readonly RC_NOIMGDATA=3
    readonly MSG_NOIMGDATA="No image data in clipboard"

    test $# -gt 0 || usage
    OUT_FILE=$1

    # TODO This is horrible; arguably violates DRY, and isn't particularly useful. switch to if statements instead
    which wslpath >/dev/null 2>&1 && PASTE_FUNC=wsl_paste && return 0
    test -v WAYLAND_DISPLAY && which wl-paste >/dev/null 2>&1 && PASTE_FUNC=wl_paste && return 0
    test -v DISPLAY && which xclip >/dev/null 2>&1 && PASTE_FUNC=xclip_paste && return 0
    echo "No clipboard command found." >&2
    exit 2
}

function prepare() {
    OUT_DIR=$(dirname $OUT_FILE)
    mkdir -p $OUT_DIR
    trap cleanup EXIT
}

function cleanup() {
    # if $OUT_FILE is empty, remove it.
    test -s $OUT_FILE || rm -f $OUT_FILE
}

function wsl_paste() {
    # wslpath in old WSL needs existance of $OUT_FILE
    local outfile=$(wslpath -w $OUT_FILE)
    touch $OUT_FILE
    local cmdline=$(cat << EOF
        \$img = get-clipboard -format image
        if (\$img -eq \$null) {
            [System.Console]::Error.WriteLine("$MSG_NOIMGDATA")
            Exit $RC_NOIMGDATA
        }
        echo "Saving image to $outfile"
        \$img.save("$outfile")
EOF
    )

    powershell.exe -command "$cmdline"
}

function wl_paste() {
    wl-paste --list-types | grep -q image/png || {
        echo "$MSG_NOIMGDATA" >&2
        return $RC_NOIMGDATA
    }
    wl-paste --no-newline --type image/png > $OUT_FILE
}

function xclip_paste() {
    xclip -selection clipboard -t TARGETS -o | grep -q image/png || {
        echo "$MSG_NOIMGDATA" >&2
        return $RC_NOIMGDATA
    }
    xclip -selection clipboard -t image/png -o > $OUT_FILE
}

echo $VERSION
config "$@"
prepare
$PASTE_FUNC
ls -l $OUT_FILE

