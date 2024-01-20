$outfile = "$($args[0])"
$img = get-clipboard -format image
if ($img -eq $null) {
    Write-Host "No image data in clipboard."
    Exit 3
}
echo "Saving image to $outfile"
$img.save($outfile)
