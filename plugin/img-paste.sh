#!/bin/bash
VERSION="img-paste.sh ver 0.2.0 (01/20/2024)"
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
    test $# -gt 0 || usage
    OUT_FILE=$1
    which wslpath >/dev/null 2>&1 && PROC=wsl_paste && return 0
    test -v WAYLAND_DISPLAY && which wl-paste >/dev/null 2>&1 && PROC=wl_paste && return 0
    test -v DISPLAY && which xclip >/dev/null 2>&1 && PROC=xclip_paste && return 0
    echo "No clipboard command found." >&2
    exit 1
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
    touch $OUT_FILE
    local outfile=$(wslpath -w $OUT_FILE)
    local cmdline1="Add-Type -AssemblyName System.Windows.Forms"
    local cmdline2="[System.Windows.Forms.Clipboard]::GetImage().Save"
    local cmdline="$cmdline1;$cmdline2('$outfile')"
    powershell.exe -command "$cmdline"
}

function wl_paste() {
    wl-paste --list-types | grep -q image/png || {
        echo "No image in clipboard." >&2
        return 1
    }
    wl-paste --no-newline --type image/png > $OUT_FILE
}

function xclip_paste() {
    xclip -selection clipboard -t TARGETS -o | grep -q image/png || {
        echo "No image in clipboard." >&2
        return 1
    }
    xclip -selection clipboard -t image/png -o > $OUT_FILE
}

function main() {
    echo $VERSION
    config "$@"
    prepare
    $PROC
    ls -l $OUT_FILE
}

main "$@"
