-- Migracion: un mismo negocio puede tener varios "canales" de catalogo
-- (retail = tienda al publico, distribuidora = novedades mayoristas, textos = textos escolares, elt = ingles para institutos).
-- Aditiva: lo que ya existe queda como canal 'retail'.

ALTER TABLE productos ADD COLUMN IF NOT EXISTS canal     TEXT NOT NULL DEFAULT 'retail';
ALTER TABLE productos ADD COLUMN IF NOT EXISTS editorial TEXT;

-- el sku (ISBN o id de tienda) pasa a ser unico por negocio y canal
DROP INDEX IF EXISTS productos_negocio_sku_uq;
CREATE UNIQUE INDEX IF NOT EXISTS productos_negocio_canal_sku_uq ON productos (negocio_id, canal, sku);
CREATE INDEX IF NOT EXISTS idx_productos_canal ON productos (negocio_id, canal);
