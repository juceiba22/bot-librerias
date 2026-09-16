param(
    [int]$MaxPerCategoria = 30
)

$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

function Get-ProductosDePagina {
    param([string]$Url, [string]$Segmento)

    try {
        $r = Invoke-WebRequest -Uri $Url -UserAgent $ua -UseBasicParsing -TimeoutSec 20
    } catch {
        Write-Warning "No se pudo obtener $Url : $($_.Exception.Message)"
        return @()
    }

    $blocks = [regex]::Matches($r.Content, "<script type=`"application/ld\+json`"[^>]*>(.*?)</script>", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $productos = @()

    foreach ($b in $blocks) {
        $json = $b.Groups[1].Value.Trim()
        if ($json -notmatch '"@type"\s*:\s*"Product"') { continue }

        try {
            $obj = $json | ConvertFrom-Json
        } catch {
            continue
        }

        $productos += [PSCustomObject]@{
            segmento_demo = $Segmento
            nombre        = $obj.name
            sku           = $obj.sku
            marca         = $obj.brand.name
            precio        = $obj.offers.price
            moneda        = $obj.offers.priceCurrency
            disponibilidad = ($obj.offers.availability -replace "https://schema.org/", "")
            stock         = $obj.offers.inventoryLevel.value
            url_producto  = $obj.offers.url
            imagen        = $obj.image
            url_origen    = $Url
        }
    }

    return $productos
}

# --- Música: combinamos subcategorías del propio dominio yenny-elateneo.com ---
$musicaUrls = @(
    "https://www.yenny-elateneo.com/musica/rp-internacional/",
    "https://www.yenny-elateneo.com/musica/musica-clasica/",
    "https://www.yenny-elateneo.com/musica/jazz/"
)

$musica = @()
foreach ($u in $musicaUrls) {
    Write-Output "Scrapeando MUSICA: $u"
    $musica += Get-ProductosDePagina -Url $u -Segmento "musica"
    Start-Sleep -Milliseconds 800
}
$musica = $musica | Sort-Object sku -Unique | Select-Object -First $MaxPerCategoria

# --- Más vendidos: solo existe en tematika.com (mismo grupo, no en yenny-elateneo.com) ---
$masVendidosUrls = @(
    "https://www.tematika.com/ranking-mas-vendidos/",
    "https://www.tematika.com/ranking-mas-vendidos/?page=2",
    "https://www.tematika.com/ranking-mas-vendidos/?page=3"
)

$masVendidos = @()
foreach ($u in $masVendidosUrls) {
    Write-Output "Scrapeando MAS VENDIDOS: $u"
    $masVendidos += Get-ProductosDePagina -Url $u -Segmento "mas_vendidos"
    Start-Sleep -Milliseconds 800
}
$masVendidos = $masVendidos | Sort-Object sku -Unique | Select-Object -First $MaxPerCategoria

# --- Export ---
$outDir = $PSScriptRoot
$musica | Export-Csv -Path (Join-Path $outDir "musica_demo.csv") -NoTypeInformation -Encoding UTF8
$masVendidos | Export-Csv -Path (Join-Path $outDir "mas_vendidos_demo.csv") -NoTypeInformation -Encoding UTF8
($musica + $masVendidos) | Export-Csv -Path (Join-Path $outDir "catalogo_demo.csv") -NoTypeInformation -Encoding UTF8

Write-Output "----"
Write-Output "Musica: $($musica.Count) productos"
Write-Output "Mas vendidos: $($masVendidos.Count) productos"
