-- Migracion: un mismo bot para varias librerias (cada una es un "negocio").
-- Es aditiva: los datos existentes (Yenny) pasan a un negocio inactivo.

CREATE TABLE IF NOT EXISTS negocios (
    id              SERIAL PRIMARY KEY,
    slug            TEXT UNIQUE NOT NULL,
    codigo          TEXT UNIQUE NOT NULL,        -- palabra tras el # en el link de WhatsApp (ej. #sbs)
    nombre          TEXT NOT NULL,               -- como se llama el comercio
    descripcion     TEXT,                        -- que vende / a quien atiende
    promos          TEXT,                        -- promociones y medios de pago; vacio = no las menciona
    retiro_envio    TEXT,                        -- politica de retiro y envio
    pregunta_zona   BOOLEAN NOT NULL DEFAULT FALSE,
    mostrar_links   BOOLEAN NOT NULL DEFAULT TRUE,
    notas           TEXT,                        -- instrucciones extra para el asistente
    es_default      BOOLEAN NOT NULL DEFAULT FALSE,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en       TIMESTAMPTZ DEFAULT now()
);

INSERT INTO negocios (slug, codigo, nombre, descripcion, activo)
VALUES ('yenny', 'yenny', 'Yenny El Ateneo', 'Cadena de librerias (datos de la demo anterior, desactivado)', FALSE)
ON CONFLICT (slug) DO NOTHING;

ALTER TABLE productos     ADD COLUMN IF NOT EXISTS negocio_id INTEGER REFERENCES negocios(id);
ALTER TABLE sucursales    ADD COLUMN IF NOT EXISTS negocio_id INTEGER REFERENCES negocios(id);
ALTER TABLE sucursales    ADD COLUMN IF NOT EXISTS direccion  TEXT;
ALTER TABLE sucursales    ADD COLUMN IF NOT EXISTS whatsapp   TEXT;
ALTER TABLE conversaciones ADD COLUMN IF NOT EXISTS negocio_id INTEGER REFERENCES negocios(id);

UPDATE productos  SET negocio_id = (SELECT id FROM negocios WHERE slug = 'yenny') WHERE negocio_id IS NULL;
UPDATE sucursales SET negocio_id = (SELECT id FROM negocios WHERE slug = 'yenny') WHERE negocio_id IS NULL;

-- el sku era unico global; ahora es unico por negocio
ALTER TABLE productos DROP CONSTRAINT IF EXISTS productos_sku_key;
CREATE UNIQUE INDEX IF NOT EXISTS productos_negocio_sku_uq ON productos (negocio_id, sku);
CREATE INDEX IF NOT EXISTS idx_productos_negocio ON productos (negocio_id);
CREATE INDEX IF NOT EXISTS idx_sucursales_negocio ON sucursales (negocio_id);

-- que negocio esta usando cada telefono (se fija con el codigo del link de WhatsApp)
CREATE TABLE IF NOT EXISTS sesiones (
    telefono        TEXT PRIMARY KEY,
    negocio_id      INTEGER NOT NULL REFERENCES negocios(id),
    actualizado_en  TIMESTAMPTZ DEFAULT now()
);
