-- Demo generica de Leonardo: circuito de venta completo (recomendar, ubicar sucursal,
-- medios de pago y promociones) con datos simulados, tomado del flujo de la demo anterior.
-- Idempotente: se puede volver a ejecutar.

-- Largo maximo de las respuestas, configurable por negocio (los demas siguen en 40).
ALTER TABLE negocios ADD COLUMN IF NOT EXISTS max_palabras INTEGER NOT NULL DEFAULT 40;

UPDATE negocios SET
  pregunta_zona = TRUE,
  max_palabras = 70,
  promos = 'Medios de pago: tarjetas de crédito y débito, transferencia, Mercado Pago y efectivo en sucursal. Promoción vigente: Banco Nación los sábados, 10% de ahorro (tope $10.000 por compra) más 3 cuotas sin interés con Visa y Mastercard crédito, válido online y en sucursales.',
  retiro_envio = 'Se puede comprar online con envío a domicilio o retirar sin cargo en la sucursal que elija el cliente. Los plazos y costos de envío los confirma el equipo.',
  notas = 'Esta es una demostración: las sucursales, los precios, el stock y las promociones son de ejemplo. Hablá de ellos con total naturalidad, como si fueran reales, y aclará que son ilustrativos solo si el cliente pregunta si son reales. '
       || 'Conversá en capas, sin ser rígido ni robótico: 1) escuchá qué busca y recomendá 2 o 3 productos con su precio, contando en una frase por qué cada uno puede gustarle; '
       || '2) cuando el cliente muestre interés o acepte una recomendación ("me gusta", "dale", "lo quiero"), preguntale en qué zona o barrio está para ubicarle la sucursal más cercana y pasale nombre y dirección; '
       || '3) una vez que eligió producto o sucursal, ofrecele los medios de pago y la promoción vigente sin esperar a que pregunte, y cerrá preguntando si quiere que se lo reserven para retirar o prefiere envío.'
WHERE slug = 'demo';

-- Sucursales de ejemplo (ficticias) para la demo generica.
DELETE FROM sucursales WHERE negocio_id IN (SELECT id FROM negocios WHERE slug = 'demo');

INSERT INTO sucursales (negocio_id, nombre, direccion, telefono, whatsapp)
SELECT n.id, v.nombre, v.direccion, NULL, NULL
FROM negocios n
JOIN (VALUES
  ('demo', 'Sucursal Palermo',      'Av. Santa Fe 3200, Palermo, Ciudad Autónoma de Buenos Aires'),
  ('demo', 'Sucursal Belgrano',     'Av. Cabildo 2100, Belgrano, Ciudad Autónoma de Buenos Aires'),
  ('demo', 'Sucursal Caballito',    'Av. Rivadavia 5200, Caballito, Ciudad Autónoma de Buenos Aires'),
  ('demo', 'Sucursal Microcentro',  'Florida 450, Ciudad Autónoma de Buenos Aires'),
  ('demo', 'Sucursal San Isidro',   'Av. Centenario 300, San Isidro, zona norte del Gran Buenos Aires'),
  ('demo', 'Sucursal Lomas de Zamora', 'Laprida 150, Lomas de Zamora, zona sur del Gran Buenos Aires'),
  ('demo', 'Sucursal La Plata',     'Calle 8 entre 47 y 48, La Plata'),
  ('demo', 'Sucursal Córdoba',      'Av. Colón 800, Córdoba'),
  ('demo', 'Sucursal Rosario',      'Calle Córdoba 1300, Rosario')
) AS v(slug, nombre, direccion) ON v.slug = n.slug;
