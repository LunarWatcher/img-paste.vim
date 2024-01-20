$outfile = "$($args[0])"
$img = get-clipboard -format image
if ($img -eq $null) {
    [System.Console]::Error.WriteLine("No image data in clipboard")
    Exit 3
}
echo "Saving image to $outfile"
$img.save($outfile)
