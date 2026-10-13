"""Carga un catalogo de demostracion de una tienda VTEX (probado con sbs.com.ar).

Usa la API publica de busqueda del catalogo (la misma que usa el sitio), a ritmo moderado,
y guarda los productos en la tabla `productos` del negocio indicado. Es un snapshot para demos:
en produccion el catalogo se conecta al sistema del cliente.

Uso:  python cargar_sbs_vtex.py [slug_negocio]      (por defecto: sbs)
"""
import html
import json
import os
import re
import sys
import time
import urllib.request

BASE = "https://www.sbs.com.ar"
RUNNER = os.environ.get("SQL_RUNNER_URL", "")  # URL del webhook utilitario de SQL (no se guarda en el repo)
SLUG = sys.argv[1] if len(sys.argv) > 1 else "sbs"
POR_CATEGORIA = 40
PAUSA = 0.7  # segundos entre llamadas

# (ruta de categoria VTEX padre/hijo, cuantos traer). "0" = ranking general de mas vendidos
CATEGORIAS = [
    ("1000119/1000261", 60),   # Infantil, juvenil y educativo / Material educativo
    ("1000119/1000257", 40),   # ... Libros para ninos: ilustrados y de actividades
    ("1000119/1000259", 40),   # ... Ficcion infantil / juvenil
    ("1000119/1000260", 30),   # ... Interes general
    ("1000119/1000263", 20),   # ... Cuestiones personales y sociales
    ("1000103/1000136", 40),   # Ficcion / general y literaria
    ("1000103/1000139", 40),   # ... Crimenes y misterio
    ("1000103/1000141", 40),   # ... Thriller / suspenso
    ("1000103/1000143", 30),   # ... Terror
    ("1000103/1000144", 30),   # ... Ciencia ficcion
    ("1000103/1000145", 30),   # ... Fantasia
    ("1000102/1000134", 30),   # Biografias y prosa de no ficcion
    ("1000102/1000132", 20),   # Poesia
    ("1000109/1000187", 30),   # Historia
    ("1000116/1000238", 30),   # Autoayuda
    ("1000105/1000165", 20),   # Psicologia
    ("1000105/1000166", 30),   # Educacion
    ("1000118/1000253", 30),   # Novela grafica / comics / manga
    ("1000101/1000130", 30),   # Ensenanza y aprendizaje de lenguas
    ("1000110/1000189", 20),   # Matematicas
    ("1000117/1000245", 20),   # Humor
    ("344", 60),               # Listas escolares por colegio
    ("0", 150),                # mas vendidos en general
]


def get(path):
    req = urllib.request.Request(BASE + path, headers={"User-Agent": "Mozilla/5.0 (demo catalog loader)"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.load(r)


def q(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("\x00", "").replace("'", "''") + "'"


def limpiar(txt, largo):
    if not txt:
        return None
    t = re.sub(r"<[^>]+>", " ", html.unescape(txt))
    t = re.sub(r"\s+", " ", t).strip()
    return t[:largo] if t else None


def nombres_categorias():
    """id -> nombre, con el arbol completo (4 niveles)."""
    mapa = {}

    def rec(nodos):
        for n in nodos:
            mapa[str(n["id"])] = n["name"].strip()
            rec(n.get("children", []))
    rec(get("/api/catalog_system/pub/category/tree/4"))
    return mapa


def primero(v):
    if isinstance(v, list):
        return v[0] if v else None
    return v


def productos_de(cat_id, cantidad):
    out = []
    desde = 0
    while len(out) < cantidad:
        hasta = min(desde + 49, desde + cantidad - 1 + 10)
        fq = f"&fq=C:/{cat_id}/" if cat_id != "0" else ""
        data = get(f"/api/catalog_system/pub/products/search?_from={desde}&_to={hasta}&O=OrderByTopSaleDESC{fq}")
        time.sleep(PAUSA)
        if not data:
            break
        out.extend(data)
        if len(data) < (hasta - desde + 1):
            break
        desde = hasta + 1
    return out[:cantidad]


def ficha(p):
    """Texto buscable: edad, idioma, nivel, editorial y sinopsis (si la hay)."""
    partes = []
    for etiqueta, clave in (("Edad", "Edad"), ("Idioma", "Idioma"), ("Nivel", "Nivel"), ("Editorial", "Editorial")):
        v = primero(p.get(clave))
        if v:
            partes.append(f"{etiqueta}: {v}.")
    sin = limpiar(primero(p.get("Sinopsis")) or p.get("description"), 400)
    if sin:
        partes.append(sin)
    return " ".join(partes) or None


def a_fila(p, nombres):
    try:
        item = p["items"][0]
        oferta = item["sellers"][0]["commertialOffer"]
    except (KeyError, IndexError):
        return None
    if not oferta.get("IsAvailable") or not oferta.get("Price"):
        return None
    ids = [i for i in ((p.get("categoriesIds") or [""])[0]).split("/") if i]
    grupo = nombres.get(ids[0], "General") if ids else "General"
    hoja = nombres.get(ids[-1], grupo) if ids else grupo
    imagen = item["images"][0]["imageUrl"] if item.get("images") else None
    return {
        "sku": str(p["productId"]),
        "nombre": p["productName"],
        "marca": p.get("brand"),
        "grupo": grupo,
        "categoria": hoja,
        "isbn": primero(p.get("ISBN")),
        "precio": oferta["Price"],
        "stock": oferta.get("AvailableQuantity"),
        "url": p.get("link"),
        "imagen": imagen,
        "descripcion": ficha(p),
    }


def main():
    if not RUNNER:
        raise SystemExit('Falta la variable de entorno SQL_RUNNER_URL')
    nombres = nombres_categorias()
    vistos = {}
    for cat_id, cantidad in CATEGORIAS:
        try:
            prods = productos_de(cat_id, cantidad)
        except Exception as e:  # una categoria que falla no frena el resto
            print(f"  categoria {cat_id}: ERROR {e}")
            continue
        nuevos = 0
        for p in prods:
            fila = a_fila(p, nombres)
            if fila and fila["sku"] not in vistos:
                vistos[fila["sku"]] = fila
                nuevos += 1
        print(f"categoria {cat_id:>16}: {len(prods):>3} traidos, {nuevos:>3} nuevos (total {len(vistos)})")

    filas = list(vistos.values())
    sub = f"(SELECT id FROM negocios WHERE slug = {q(SLUG)})"
    for i in range(0, len(filas), 60):
        lote = filas[i:i + 60]
        valores = ",\n".join(
            f"({sub}, {q(f['grupo'])}, {q(f['categoria'])}, {q(f['sku'])}, {q(f['isbn'])}, {q(f['nombre'])}, {q(f['marca'])}, {f['precio']}, 'ARS', 'InStock', "
            f"{f['stock'] if f['stock'] is not None else 'NULL'}, {q(f['url'])}, {q(f['imagen'])}, {q(f['descripcion'])})"
            for f in lote
        )
        sql = (
            "INSERT INTO productos (negocio_id, grupo, segmento_demo, sku, isbn, nombre, marca, precio, moneda, disponibilidad, stock, url_producto, imagen, descripcion) VALUES\n"
            + valores
            + "\nON CONFLICT (negocio_id, canal, sku) DO UPDATE SET nombre = EXCLUDED.nombre, marca = EXCLUDED.marca, precio = EXCLUDED.precio, "
              "stock = EXCLUDED.stock, url_producto = EXCLUDED.url_producto, imagen = EXCLUDED.imagen, descripcion = EXCLUDED.descripcion, "
              "segmento_demo = EXCLUDED.segmento_demo, grupo = EXCLUDED.grupo, isbn = EXCLUDED.isbn, actualizado_en = now();"
        )
        req = urllib.request.Request(RUNNER, data=json.dumps({"sql": sql}).encode("utf-8"),
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=60) as r:
            resp = r.read().decode("utf-8")[:80]
        print(f"lote {i // 60 + 1}: {len(lote)} filas -> {resp}")
    print(f"listo: {len(filas)} productos cargados en el negocio '{SLUG}'")


if __name__ == "__main__":
    main()
