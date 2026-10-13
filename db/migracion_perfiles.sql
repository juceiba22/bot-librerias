-- Tipos de cliente ("perfiles") por negocio.
-- Un negocio con mas de un perfil hace que el bot pregunte con quien habla y recuerde la respuesta.
-- Cada perfil define que canales de catalogo consulta y que instrucciones recibe el asistente.
-- Los negocios sin perfiles (Rayuela, demo) se comportan como siempre.

CREATE TABLE IF NOT EXISTS perfiles (
    id            SERIAL PRIMARY KEY,
    negocio_id    INTEGER NOT NULL REFERENCES negocios(id),
    codigo        TEXT NOT NULL,
    nombre        TEXT NOT NULL,          -- como se le nombra al cliente
    pista         TEXT NOT NULL,          -- descripcion para clasificar el mensaje
    canales       TEXT[] NOT NULL,        -- canales de catalogo que consulta
    instrucciones TEXT NOT NULL,          -- lo que el asistente debe saber / hacer con este tipo de cliente
    orden         INTEGER NOT NULL DEFAULT 1,
    UNIQUE (negocio_id, codigo)
);

ALTER TABLE sesiones       ADD COLUMN IF NOT EXISTS perfil_codigo TEXT;
ALTER TABLE conversaciones ADD COLUMN IF NOT EXISTS perfil TEXT;

DELETE FROM perfiles WHERE negocio_id = (SELECT id FROM negocios WHERE slug = 'sbs');

INSERT INTO perfiles (negocio_id, codigo, nombre, pista, canales, instrucciones, orden)
SELECT n.id, v.codigo, v.nombre, v.pista, v.canales, v.instrucciones, v.orden
FROM negocios n
JOIN (VALUES
 ('sbs', 'publico', 'lector o público general',
  'persona que compra para sí misma o para su familia: lectores, padres, estudiantes, quien busca un libro, un regalo o libros en inglés',
  ARRAY['retail'],
  'Es público general (lector, familia o estudiante). Recomendá libros de la tienda con su precio y el link. Si quiere retirar, ofrecele las sucursales.',
  1),
 ('sbs', 'libreria', 'librería (compra al por mayor)',
  'librería o librero que le compra a la distribuidora para revender; quiere hacerse cliente, pedir novedades o consultar condiciones mayoristas',
  ARRAY['distribuidora','textos','elt'],
  'Es una librería que le compra a SBS Distribuidora para revender (más de 30 años de trayectoria, más de 1.500 clientes libreros, más de 600 fondos editoriales). Los precios de los listados son precios de lista (PVP), NO el precio mayorista: nunca los presentes como precio de compra; descuentos y condiciones los informa el equipo de ventas. Podés buscar novedades por título, autor, ISBN o sello. Si todavía no es cliente: debe completar el formulario de alta (se descarga en https://www.sbs.com.ar/clientes-mayoristas) y enviarlo por mail a admventas@sbs.com.ar; se le asigna un número de cliente que debe usar en todo pedido o consulta. Pedidos: sistema de autogestión web (permite hacer pedidos, ver catálogos, consultar stock y seguir la cuenta corriente), WhatsApp https://wa.me/5491162223330, teléfono 011 5353-2220 o mail ventas@sbs.com.ar. Horarios: temporada baja de lunes a viernes de 9 a 20; temporada alta o inicio escolar de lunes a viernes de 8 a 22 y sábados de 9 a 18. Entregas sin costo ni monto mínimo en CABA, GBA Sur, Oeste y Norte, Pilar, Campana, Zárate, La Plata, Luján y Mercedes; fuera del AMBA en San Pedro, San Nicolás, Rosario y Córdoba capital; en otras localidades la mercadería se retira en la distribuidora o se despacha por expreso de preferencia o por Andreani. No tenés acceso a stock real, cuenta corriente ni pedidos: para eso derivá a la autogestión web o al equipo de ventas, y nunca pidas ni muestres datos de cuenta.',
  2),
 ('sbs', 'institucion', 'colegio, instituto o universidad',
  'colegio, escuela, instituto de idiomas, universidad o docente que busca textos escolares o material de inglés para sus alumnos',
  ARRAY['textos','elt'],
  'Es una institución educativa (colegio, instituto de idiomas o universidad) o un docente. Ayudalo a encontrar textos escolares y material de inglés (ELT) de los listados. Para cotizar, preguntale el nivel o curso y la cantidad aproximada de alumnos. Los precios son de lista; las condiciones para instituciones las coordina el equipo comercial (más información en https://www.sbs.com.ar/instituciones-educativas). No tenés listas armadas por colegio: no las inventes.',
  3)
) AS v(slug, codigo, nombre, pista, canales, instrucciones, orden) ON v.slug = n.slug;
