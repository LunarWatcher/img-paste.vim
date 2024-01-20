## Files

- mdip.vim: main script, call img-paste.*
- img-paste.sh: run on Linux, WSL
- img-paste.ps1: run on Windows

Run img-paste.* standalone for debugging.

## Remarks 1

On Windows, we can run img-paste.ps1 directly. However, if we run it on WSL as:

```
powershell.exe ./img-paste.ps1
```

will get the error:

```
\\wsl.localhost\Ubuntu-22.04\...\img-paste.vim\plugin\img-paste.ps1 is not
digitally signed. You cannot run this script on the current system.
```

So I have to embedded the code to img-paste.sh for WSL. i.e. we can call the command lines, but not script file.

```bash
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
```

## Remarks 2

The latest WSL supports X Window. In theory, we can run WSL as Linux exactly, using ws-paste or
xclip.

I tried, but none works.
