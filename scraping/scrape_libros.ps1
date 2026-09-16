param(
    [int]$MaxPerCategoria = 20
)

$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

$categorias = @(
    @{ segmento = "libros_infantil";    url = "https://www.yenny-elateneo.com/libros/infantil-y-juvenil/" },
    @{ segmento = "libros_policial";    url = "https://www.yenny-elateneo.com/libros/ficcion-y-literatura/novelas/policial2/" },
    @{ segmento = "libros_economia";    url = "https://www.yenny-elateneo.com/libros/negocios-y-cs-economicas/economia/" },
    @{ segmento = "libros_tecnologia";  url = "https://www.yenny-elateneo.com/libros/computacion-y-sistemas/" }
)

$rows = @()

foreach ($cat in $categorias) {
    Write-Output "Scrapeando $($cat.segmento): $($cat.url)"
    try {
        $r = Invoke-WebRequest -Uri $cat.url -UserAgent $ua -UseBasicParsing
        $content = $r.Content
        $matches = [regex]::Matches($content, '<script type="application/ld\+json"[^>]*>(.*?)</script>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $count = 0
        foreach ($m in $matches) {
            if ($count -ge $MaxPerCategoria) { break }
            $jsonText = $m.Groups[1].Value.Trim()
            try {
                $obj = $jsonText | ConvertFrom-Json
            } catch { continue }
            if ($obj.'@type' -ne 'Product') { continue }

            $nombre = $obj.name
            $sku = $obj.sku
            $marca = if ($obj.brand.name) { $obj.brand.name } else { "" }
            $urlProducto = $obj.mainEntityOfPage.'@id'
            $imagen = $obj.image
            $offer = $obj.offers
            $precio = if ($offer.price) { $offer.price } else { "" }
            $moneda = if ($offer.priceCurrency) { $offer.priceCurrency } else { "ARS" }
            $disponibilidad = if ($offer.availability) { ($offer.availability -replace '.*/', '') } else { "" }

            $rows += [PSCustomObject]@{
                segmento_demo   = $cat.segmento
                nombre          = $nombre
                sku             = $sku
                marca           = $marca
                precio          = $precio
                moneda          = $moneda
                disponibilidad  = $disponibilidad
                stock           = ""
                url_producto    = $urlProducto
                imagen          = $imagen
                url_origen      = $cat.url
            }
            $count++
        }
        Write-Output "  -> $count productos"
    } catch {
        Write-Output "  ERROR: $($_.Exception.Message)"
    }
}

$rows | Export-Csv -Path "libros_demo.csv" -NoTypeInformation -Encoding UTF8
Write-Output "Total productos: $($rows.Count)"
