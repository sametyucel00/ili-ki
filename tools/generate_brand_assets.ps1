$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$brandingDir = Join-Path $root "assets\branding"
$androidRes = Join-Path $root "android\app\src\main\res"
$iosIcons = Join-Path $root "ios\Runner\Assets.xcassets\AppIcon.appiconset"
$iosLaunch = Join-Path $root "ios\Runner\Assets.xcassets\LaunchImage.imageset"

New-Item -ItemType Directory -Force -Path $brandingDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $androidRes "drawable-nodpi") | Out-Null

function New-Bitmap($width, $height) {
    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $bmp.SetResolution(96, 96)
    return $bmp
}

function Add-RoundedRect([System.Drawing.Drawing2D.GraphicsPath]$path, [float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
    $diameter = $radius * 2
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
}

function Draw-HeartMark($graphics, $centerX, $centerY, $scale, $penColor) {
    $heartPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $heartPath.AddBezier(
        $centerX, $centerY + (20 * $scale),
        $centerX - (70 * $scale), $centerY - (35 * $scale),
        $centerX - (105 * $scale), $centerY + (45 * $scale),
        $centerX, $centerY + (105 * $scale)
    )
    $heartPath.AddBezier(
        $centerX, $centerY + (105 * $scale),
        $centerX + (105 * $scale), $centerY + (45 * $scale),
        $centerX + (70 * $scale), $centerY - (35 * $scale),
        $centerX, $centerY + (20 * $scale)
    )
    $pen = New-Object System.Drawing.Pen $penColor, (14 * $scale)
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawPath($pen, $heartPath)
    $pen.Dispose()
    $heartPath.Dispose()
}

function Draw-ChatBubbles($graphics, $centerX, $centerY, $scale, $fill1, $fill2) {
    $path1 = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-RoundedRect $path1 ([float]($centerX - (175 * $scale))) ([float]($centerY - (155 * $scale))) ([float](150 * $scale)) ([float](112 * $scale)) ([float](34 * $scale))
    $path1.AddPolygon(@(
        (New-Object System.Drawing.PointF([float]($centerX - (85 * $scale)), [float]($centerY - (50 * $scale)))),
        (New-Object System.Drawing.PointF([float]($centerX - (55 * $scale)), [float]($centerY - (22 * $scale)))),
        (New-Object System.Drawing.PointF([float]($centerX - (104 * $scale)), [float]($centerY - (20 * $scale))))
    ))

    $path2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-RoundedRect $path2 ([float]($centerX + (25 * $scale))) ([float]($centerY - (135 * $scale))) ([float](150 * $scale)) ([float](112 * $scale)) ([float](34 * $scale))
    $path2.AddPolygon(@(
        (New-Object System.Drawing.PointF([float]($centerX + (95 * $scale)), [float]($centerY - (20 * $scale)))),
        (New-Object System.Drawing.PointF([float]($centerX + (50 * $scale)), [float]($centerY - (12 * $scale)))),
        (New-Object System.Drawing.PointF([float]($centerX + (88 * $scale)), [float]($centerY - (46 * $scale))))
    ))

    $graphics.FillPath((New-Object System.Drawing.SolidBrush $fill1), $path1)
    $graphics.FillPath((New-Object System.Drawing.SolidBrush $fill2), $path2)
    $path1.Dispose()
    $path2.Dispose()
}

function Draw-Brand($size, $outputPath, $includeText) {
    $bmp = New-Bitmap $size $size
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 245, 238, 232))

    $rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 246, 221, 211),
        [System.Drawing.Color]::FromArgb(255, 181, 106, 99),
        50
    )
    $graphics.FillRectangle($brush, $rect)

    $glow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(42, 255, 255, 255))
    $graphics.FillEllipse($glow, $size * 0.08, $size * 0.1, $size * 0.72, $size * 0.72)
    $graphics.FillEllipse($glow, $size * 0.34, $size * 0.28, $size * 0.54, $size * 0.54)

    $circleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 248, 244))
    $graphics.FillEllipse($circleBrush, $size * 0.18, $size * 0.16, $size * 0.64, $size * 0.64)

    Draw-ChatBubbles $graphics ($size / 2) ($size / 2) ($size / 1024.0) ([System.Drawing.Color]::FromArgb(255, 239, 209, 199)) ([System.Drawing.Color]::FromArgb(255, 246, 224, 216))
    Draw-HeartMark $graphics ($size / 2) ($size / 2 - ($size * 0.01)) ($size / 1024.0) ([System.Drawing.Color]::FromArgb(255, 181, 106, 99))

    if ($includeText) {
        $titleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 58, 41, 40))
        $subtitleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 107, 91, 88))
        $titleFont = New-Object System.Drawing.Font("Georgia", [float]($size * 0.085), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $subtitleFont = New-Object System.Drawing.Font("Segoe UI", [float]($size * 0.037), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
        $format = New-Object System.Drawing.StringFormat
        $format.Alignment = [System.Drawing.StringAlignment]::Center
        $graphics.DrawString("İlişki Koçu AI", $titleFont, $titleBrush, [float]($size / 2), [float]($size * 0.73), $format)
        $graphics.DrawString("Sakin, dengeli, yorumlayıcı iletişim desteği", $subtitleFont, $subtitleBrush, [float]($size / 2), [float]($size * 0.83), $format)
        $titleFont.Dispose()
        $subtitleFont.Dispose()
        $titleBrush.Dispose()
        $subtitleBrush.Dispose()
        $format.Dispose()
    }

    $brush.Dispose()
    $glow.Dispose()
    $circleBrush.Dispose()
    $graphics.Dispose()
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Resize-Png($sourcePath, $size, $destinationPath) {
    $source = [System.Drawing.Image]::FromFile($sourcePath)
    $bitmap = New-Bitmap $size $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($source, 0, 0, $size, $size)
    $bitmap.Save($destinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
    $source.Dispose()
}

$masterIcon = Join-Path $brandingDir "app-icon-master.png"
$splashArt = Join-Path $brandingDir "splash-brand.png"

Draw-Brand 1024 $masterIcon $false
Draw-Brand 1600 $splashArt $true

$androidMap = @{
    "mipmap-mdpi\ic_launcher.png" = 48
    "mipmap-hdpi\ic_launcher.png" = 72
    "mipmap-xhdpi\ic_launcher.png" = 96
    "mipmap-xxhdpi\ic_launcher.png" = 144
    "mipmap-xxxhdpi\ic_launcher.png" = 192
}

foreach ($item in $androidMap.GetEnumerator()) {
    Resize-Png $masterIcon $item.Value (Join-Path $androidRes $item.Key)
}

Resize-Png $masterIcon 512 (Join-Path $brandingDir "android-play-icon.png")
Resize-Png $splashArt 512 (Join-Path $androidRes "drawable-nodpi\launch_brand.png")

$iosMap = @{
    "Icon-App-20x20@1x.png" = 20
    "Icon-App-20x20@2x.png" = 40
    "Icon-App-20x20@3x.png" = 60
    "Icon-App-29x29@1x.png" = 29
    "Icon-App-29x29@2x.png" = 58
    "Icon-App-29x29@3x.png" = 87
    "Icon-App-40x40@1x.png" = 40
    "Icon-App-40x40@2x.png" = 80
    "Icon-App-40x40@3x.png" = 120
    "Icon-App-60x60@2x.png" = 120
    "Icon-App-60x60@3x.png" = 180
    "Icon-App-76x76@1x.png" = 76
    "Icon-App-76x76@2x.png" = 152
    "Icon-App-83.5x83.5@2x.png" = 167
    "Icon-App-1024x1024@1x.png" = 1024
}

foreach ($item in $iosMap.GetEnumerator()) {
    Resize-Png $masterIcon $item.Value (Join-Path $iosIcons $item.Key)
}

Resize-Png $splashArt 220 (Join-Path $iosLaunch "LaunchImage.png")
Resize-Png $splashArt 440 (Join-Path $iosLaunch "LaunchImage@2x.png")
Resize-Png $splashArt 660 (Join-Path $iosLaunch "LaunchImage@3x.png")
