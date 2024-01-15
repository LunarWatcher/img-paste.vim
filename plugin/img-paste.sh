#!/bin/bash
VERSION="img-paste.sh ver 0.1.0 (01/16/2024)"
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
    PROC=linux_paste
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
    local outfile=$(wslpath -w $OUT_FILE)
    local cmdline1="Add-Type -AssemblyName System.Windows.Forms"
    local cmdline2="[System.Windows.Forms.Clipboard]::GetImage().Save"
    local cmdline="$cmdline1;$cmdline2('$outfile')"
    powershell.exe -command "$cmdline"
}

function linux_paste() {
    xclip -selection clipboard -t image/png -o > $OUT_FILE
}

function main() {
    echo $VERSION
    config "$@"
    prepare
    $PROC
    echo $OUT_FILE
    ls -l $OUT_FILE
}

main "$@"
