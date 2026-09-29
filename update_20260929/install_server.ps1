$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
$preparedRoot = Join-Path $packageRoot 'addons'
$liveRoot = 'Z:\garrysmod\addons'
$expected = Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'original_hashes.json') | ConvertFrom-Json
foreach ($entry in $expected.PSObject.Properties) {
    $livePath = Join-Path $liveRoot $entry.Name
    $actual = (Get-FileHash -LiteralPath $livePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $entry.Value) { throw "Source changed since review: $($entry.Name). No files installed." }
}
$assets = Get-ChildItem -LiteralPath $preparedRoot -Recurse -File
foreach ($asset in $assets) {
    if ($asset.Extension -eq '.png') {
        if ($asset.Length -le 0) { throw "Empty asset: $($asset.FullName)" }
    }
}
$required = Get-Content -Raw -LiteralPath (Join-Path $packageRoot 'asset_files.json') | ConvertFrom-Json
foreach ($name in $required) {
    $path = Join-Path $preparedRoot ('cases_systemlasted2\materials\cases_system\rewards\v2\' + $name)
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing case artwork: $name" }
}
$order = $assets | Sort-Object @{Expression={ if ($_.Extension -ne '.lua') {0} elseif ($_.Name -eq 'sh_config.lua') {1} else {2} }},FullName
$installed = @()
foreach ($asset in $order) {
    $relative = $asset.FullName.Substring($preparedRoot.Length).TrimStart('\')
    $target = Join-Path $liveRoot $relative
    if (Test-Path -LiteralPath $target) {
        $backup = Join-Path (Join-Path $packageRoot 'rollback_server') $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
        Copy-Item -LiteralPath $target -Destination $backup
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $asset.FullName -Destination $target
    if ((Get-Item -LiteralPath $target).Length -ne $asset.Length) { throw "Copy size mismatch: $relative" }
    if ($asset.Extension -eq '.lua') {
        if ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $asset.FullName).Hash) { throw "Lua copy checksum mismatch: $relative" }
    }
    $installed += $relative
}
$mirror = 'Z:\garrysmod\materials\onyx_phone\icons'
New-Item -ItemType Directory -Path $mirror -Force | Out-Null
$rootImages = $assets | Where-Object { $_.Extension -eq '.png' } | Group-Object Name | ForEach-Object { $_.Group[0] }
foreach ($image in $rootImages) { Copy-Item -LiteralPath $image.FullName -Destination (Join-Path $mirror $image.Name) }
$installed | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $packageRoot 'installed_files.json') -Encoding UTF8
Write-Output "Installed $($installed.Count) addon files and $($rootImages.Count) shared icon copies. Server restart and client reconnect required."

