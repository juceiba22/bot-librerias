-- Esquema demo: catalogo Yenny-El Ateneo para bot de WhatsApp
-- Pensado para Postgres en Railway. Ejecutar una sola vez.

CREATE TABLE IF NOT EXISTS productos (
    id              SERIAL PRIMARY KEY,
    segmento_demo   TEXT NOT NULL,          -- 'musica' | 'mas_vendidos' (categorias elegidas para esta demo)
    sku             TEXT UNIQUE NOT NULL,
    nombre          TEXT NOT NULL,
    marca           TEXT,
    precio          NUMERIC(12,2),
    moneda          TEXT DEFAULT 'ARS',
    disponibilidad  TEXT,                   -- InStock | OutOfStock
    stock           INTEGER,
    url_producto    TEXT,
    imagen          TEXT,
    url_origen      TEXT,                   -- pagina de origen del scraping (dominio + categoria)
    creado_en       TIMESTAMPTZ DEFAULT now(),
    actualizado_en  TIMESTAMPTZ DEFAULT now()
);

-- Busqueda rapida por nombre (el bot va a buscar asi en Fase 4)
CREATE INDEX IF NOT EXISTS idx_productos_nombre ON productos USING gin (to_tsvector('spanish', nombre));
CREATE INDEX IF NOT EXISTS idx_productos_segmento ON productos (segmento_demo);

-- Extension opcional para Fase 4 (busqueda semantica / "recomendame algo de terror")
-- Descomentar cuando integremos embeddings:
-- CREATE EXTENSION IF NOT EXISTS vector;
-- ALTER TABLE productos ADD COLUMN embedding vector(1536);
