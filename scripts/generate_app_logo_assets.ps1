param(
  [string]$SourceAsset = 'assets/images/ChatGPT_Image_Mar_24__2026__08_23_49_AM-removebg-preview.png'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Drawing

function New-ResizedIconBitmap {
  param(
    [System.Drawing.Image]$SourceImage,
    [int]$Size,
    [double]$PaddingRatio = 0.08
  )

  $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

  try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $paddedSize = [double]($Size * (1 - ($PaddingRatio * 2)))
    $scale = [Math]::Min(
      $paddedSize / [double]$SourceImage.Width,
      $paddedSize / [double]$SourceImage.Height
    )

    $drawWidth = [single]($SourceImage.Width * $scale)
    $drawHeight = [single]($SourceImage.Height * $scale)
    $drawX = [single](($Size - $drawWidth) / 2)
    $drawY = [single](($Size - $drawHeight) / 2)

    $destinationRect = [System.Drawing.RectangleF]::new($drawX, $drawY, $drawWidth, $drawHeight)
    $graphics.DrawImage($SourceImage, $destinationRect)

    return $bitmap
  }
  catch {
    $bitmap.Dispose()
    throw
  }
  finally {
    $graphics.Dispose()
  }
}

function Write-Png {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path
  )

  $directory = Split-Path -Path $Path -Parent
  if (-not (Test-Path -Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Write-IcoFromPng {
  param(
    [string]$PngPath,
    [string]$IcoPath
  )

  $pngBytes = [System.IO.File]::ReadAllBytes($PngPath)
  $stream = [System.IO.File]::Open($IcoPath, [System.IO.FileMode]::Create)
  $writer = [System.IO.BinaryWriter]::new($stream)

  try {
    $writer.Write([UInt16]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]1)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]$pngBytes.Length)
    $writer.Write([UInt32]22)
    $writer.Write($pngBytes)
  }
  finally {
    $writer.Dispose()
    $stream.Dispose()
  }
}

$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$sourcePath = Join-Path $projectRoot $SourceAsset

if (-not (Test-Path -Path $sourcePath)) {
  throw "Source asset not found: $sourcePath"
}

$targets = @(
  @{ Size = 1024; Path = 'assets/images/app_icon_master.png' },
  @{ Size = 1024; Path = 'assets/images/app_logo.png' },
  @{ Size = 512; Path = 'web/icons/Icon-512.png' },
  @{ Size = 512; Path = 'web/icons/Icon-maskable-512.png' },
  @{ Size = 192; Path = 'web/icons/Icon-192.png' },
  @{ Size = 192; Path = 'web/icons/Icon-maskable-192.png' },
  @{ Size = 48; Path = 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png' },
  @{ Size = 72; Path = 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png' },
  @{ Size = 96; Path = 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png' },
  @{ Size = 144; Path = 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png' },
  @{ Size = 192; Path = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' },
  @{ Size = 32; Path = 'web/favicon.png' }
)

$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

try {
  foreach ($target in $targets) {
    $bitmap = New-ResizedIconBitmap -SourceImage $sourceImage -Size $target.Size
    try {
      Write-Png -Bitmap $bitmap -Path (Join-Path $projectRoot $target.Path)
    }
    finally {
      $bitmap.Dispose()
    }
  }

  $windowsPngPath = Join-Path $projectRoot 'windows/runner/resources/app_icon.png'
  $windowsBitmap = New-ResizedIconBitmap -SourceImage $sourceImage -Size 256
  try {
    Write-Png -Bitmap $windowsBitmap -Path $windowsPngPath
  }
  finally {
    $windowsBitmap.Dispose()
  }

  Write-IcoFromPng -PngPath $windowsPngPath -IcoPath (Join-Path $projectRoot 'windows/runner/resources/app_icon.ico')
  Remove-Item -Path $windowsPngPath -Force
}
finally {
  $sourceImage.Dispose()
}
