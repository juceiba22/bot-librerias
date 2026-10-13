-- Negocios de demostracion: SBS, Rayuela y una demo generica (default).
-- Idempotente: se puede volver a ejecutar.

ALTER TABLE productos  ADD COLUMN IF NOT EXISTS descripcion TEXT;
ALTER TABLE sucursales ADD COLUMN IF NOT EXISTS telefono    TEXT;
ALTER TABLE sucursales ALTER COLUMN regional DROP NOT NULL;   -- solo aplica a Yenny

-- ---------------------------------------------------------------- negocios
INSERT INTO negocios (slug, codigo, nombre, descripcion, promos, retiro_envio, pregunta_zona, mostrar_links, notas, es_default, activo) VALUES
('demo', 'demo', 'Librería Demo',
 'Librería generalista de demostración: ficción y no ficción, clásicos, infantil y juvenil, novela gráfica y manga.',
 NULL,
 'La compra y el retiro se coordinan con el equipo de la librería.',
 FALSE, FALSE,
 'Catálogo de ejemplo con precios ilustrativos. Si preguntan por la veracidad de precios o stock, aclará que es una demostración y que en producción se conecta al sistema real de la librería.',
 TRUE, TRUE),
('sbs', 'sbs', 'SBS Librerías',
 'Cadena de librerías con tienda online. Vende ficción y no ficción, libros infantiles y juveniles, libros en inglés y material educativo: listas escolares y textos para colegios. También atiende a instituciones educativas y a clientes mayoristas.',
 'Hay promociones bancarias con reintegro y cuotas sin interés que cambian según el día. No des porcentajes ni días concretos: indicá que el detalle vigente está en la sección de beneficios y promociones del sitio.',
 'Se puede comprar online o retirar en una sucursal. Los plazos, costos de envío y reserva para retiro los coordina el equipo: no los confirmes.',
 FALSE, TRUE,
 'Si el cliente pregunta por la lista de un colegio, pedile el nombre del colegio y el curso. Si quiere retirar, ofrecele las sucursales de la lista y pasale la dirección y el teléfono de la que elija.',
 FALSE, TRUE),
('rayuela', 'rayuela', 'Rayuela Libros',
 'Cadena de librerías de Salta con 4 locales. Cada sucursal atiende por su propio WhatsApp.',
 NULL,
 'Se compra y se retira en la sucursal que elija el cliente.',
 TRUE, TRUE,
 'Cuando el cliente quiera comprar, reservar o hablar con una persona, preguntale qué sucursal le queda más cómoda y pasale el link de WhatsApp de esa sucursal para que cierre allí. Los precios y el stock de esta demo son ilustrativos hasta conectar el sistema de la librería.',
 FALSE, TRUE)
ON CONFLICT (slug) DO UPDATE SET
  nombre = EXCLUDED.nombre, descripcion = EXCLUDED.descripcion, promos = EXCLUDED.promos,
  retiro_envio = EXCLUDED.retiro_envio, pregunta_zona = EXCLUDED.pregunta_zona,
  mostrar_links = EXCLUDED.mostrar_links, notas = EXCLUDED.notas,
  es_default = EXCLUDED.es_default, activo = EXCLUDED.activo;

-- ------------------------------------------------------------- sucursales
DELETE FROM sucursales WHERE negocio_id IN (SELECT id FROM negocios WHERE slug IN ('sbs','rayuela'));

INSERT INTO sucursales (negocio_id, nombre, direccion, telefono, whatsapp)
SELECT n.id, v.nombre, v.direccion, v.telefono, v.whatsapp
FROM negocios n
JOIN (VALUES
  ('sbs', 'SBS Belgrano',          'Sucre 2441, Ciudad Autónoma de Buenos Aires',            '11 2160-3723', NULL),
  ('sbs', 'SBS Palermo',           'Gallo 1679, Ciudad Autónoma de Buenos Aires',            '11 3002-3022', NULL),
  ('sbs', 'SBS San Isidro',        'Martín y Omar 417, San Isidro',                          '11 3014-6313', NULL),
  ('sbs', 'SBS Lomas de Zamora',   'Gorriti 372, Lomas de Zamora',                           '11 3516-5989', NULL),
  ('sbs', 'SBS Caballito',         'Av. Rivadavia 4791, Ciudad Autónoma de Buenos Aires',    '11 6822-9226', NULL),
  ('sbs', 'SBS Rosario',           'Santa Fe 1340, Rosario',                                 '341 658-4789', NULL),
  ('sbs', 'SBS Córdoba',           'Av. Recta Martinolli 6191, Córdoba',                     '351 655-8383', NULL),
  ('sbs', 'SBS Mendoza',           'Paseo Sarmiento 234, Mendoza',                           '261 504-6726', NULL),
  ('sbs', 'SBS Salta',             'Caseros 362, Salta',                                     '387 474-3131', NULL),
  ('rayuela', 'Rayuela Alvarado 570',  'Alvarado 570, Salta',     NULL, '5493875752022'),
  ('rayuela', 'Rayuela Paseo Salta',   'Paseo Salta, Salta',      NULL, '5493876138983'),
  ('rayuela', 'Rayuela Portal Salta',  'Portal Salta, Salta',     NULL, '5493874862708'),
  ('rayuela', 'Rayuela El Punto',      'El Punto Shopping, Salta', NULL, '5493876363851')
) AS v(slug, nombre, direccion, telefono, whatsapp) ON v.slug = n.slug;

-- ------------------------------------------------- catalogo de ejemplo (demo)
DELETE FROM productos WHERE negocio_id IN (SELECT id FROM negocios WHERE slug IN ('demo','rayuela'));

INSERT INTO productos (negocio_id, segmento_demo, sku, nombre, marca, precio, moneda, disponibilidad, descripcion)
SELECT n.id, v.cat, v.sku, v.nombre, v.autor, v.precio, 'ARS', 'InStock', v.descr
FROM negocios n
JOIN (VALUES
 ('EJ-001','Novela argentina','RAYUELA','Julio Cortázar',28900,'novela experimental sobre amor, París y Buenos Aires, se puede leer en distinto orden'),
 ('EJ-002','Cuentos','FICCIONES','Jorge Luis Borges',24500,'cuentos fantásticos sobre laberintos, bibliotecas infinitas y el tiempo'),
 ('EJ-003','Cuentos','EL ALEPH','Jorge Luis Borges',22900,'cuentos sobre el infinito, la memoria y los espejos'),
 ('EJ-004','Novela argentina','SOBRE HÉROES Y TUMBAS','Ernesto Sabato',31200,'novela sobre amor, locura y la historia argentina'),
 ('EJ-005','Novela argentina','EL TÚNEL','Ernesto Sabato',19800,'novela breve psicológica sobre obsesión y celos de un pintor'),
 ('EJ-006','Novela argentina','LOS SIETE LOCOS','Roberto Arlt',23400,'novela sobre una conspiración y la Buenos Aires de los años treinta'),
 ('EJ-007','No ficción','OPERACIÓN MASACRE','Rodolfo Walsh',21500,'investigación periodística sobre los fusilamientos de 1956'),
 ('EJ-008','Novela argentina','DISTANCIA DE RESCATE','Samanta Schweblin',24900,'novela corta de terror y suspenso sobre una intoxicación y una madre'),
 ('EJ-009','Infantil','CUENTOS DE LA SELVA','Horacio Quiroga',14900,'cuentos de animales de la selva para chicos'),
 ('EJ-010','Humor gráfico','MAFALDA 1','Quino',26500,'tiras de humor sobre una nena inquieta y el mundo adulto'),
 ('EJ-011','Humor gráfico','MACANUDO 1','Liniers',22000,'tiras de humor absurdo y poético'),
 ('EJ-012','Novela argentina','NUESTRA PARTE DE NOCHE','Mariana Enriquez',39900,'novela de terror y sectas sobre un padre y su hijo en un viaje por Argentina'),
 ('EJ-013','Cuentos','LAS COSAS QUE PERDIMOS EN EL FUEGO','Mariana Enriquez',29900,'cuentos de terror y realismo cotidiano en Buenos Aires'),
 ('EJ-014','Novela argentina','COMETIERRA','Dolores Reyes',27800,'novela sobre una joven que ve crímenes al comer tierra'),
 ('EJ-015','Historieta','EL ETERNAUTA','Héctor G. Oesterheld',45900,'historieta clásica de ciencia ficción: una nevada mortal sobre Buenos Aires'),
 ('EJ-016','Novela','CIEN AÑOS DE SOLEDAD','Gabriel García Márquez',33900,'saga familiar y realismo mágico en Macondo'),
 ('EJ-017','Novela','EL AMOR EN LOS TIEMPOS DEL CÓLERA','Gabriel García Márquez',31500,'historia de amor que dura décadas'),
 ('EJ-018','Ciencia ficción','1984','George Orwell',24900,'distopía sobre vigilancia, control y totalitarismo'),
 ('EJ-019','Clásicos','REBELIÓN EN LA GRANJA','George Orwell',17900,'fábula política con animales, corta y de lectura escolar'),
 ('EJ-020','Ciencia ficción','FAHRENHEIT 451','Ray Bradbury',23500,'distopía donde los libros están prohibidos y se queman'),
 ('EJ-021','Ciencia ficción','DUNE','Frank Herbert',42900,'épica de ciencia ficción sobre poder, desierto y política'),
 ('EJ-022','Fantasía','EL SEÑOR DE LOS ANILLOS: LA COMUNIDAD DEL ANILLO','J. R. R. Tolkien',38900,'fantasía épica, aventura, viaje y batalla contra el mal'),
 ('EJ-023','Fantasía','EL HOBBIT','J. R. R. Tolkien',29900,'aventura de fantasía para todas las edades, dragones y tesoros'),
 ('EJ-024','Juvenil','HARRY POTTER Y LA PIEDRA FILOSOFAL','J. K. Rowling',27900,'fantasía juvenil sobre un niño mago y su primer año en el colegio de magia'),
 ('EJ-025','Juvenil','HARRY POTTER Y LA CÁMARA SECRETA','J. K. Rowling',28900,'fantasía juvenil, segundo año en el colegio de magia y un misterio'),
 ('EJ-026','Juvenil','LOS JUEGOS DEL HAMBRE','Suzanne Collins',26900,'distopía juvenil de supervivencia y rebelión'),
 ('EJ-027','Juvenil','PERCY JACKSON Y EL LADRÓN DEL RAYO','Rick Riordan',25900,'aventura juvenil con dioses y mitología griega'),
 ('EJ-028','Terror','ESO (IT)','Stephen King',44900,'terror clásico sobre un payaso y un grupo de amigos en un pueblo'),
 ('EJ-029','Terror','EL RESPLANDOR','Stephen King',35900,'terror en un hotel aislado en invierno'),
 ('EJ-030','Thriller','MISERY','Stephen King',31900,'suspenso psicológico: un escritor atrapado por una fan obsesiva'),
 ('EJ-031','Policial','ASESINATO EN EL ORIENT EXPRESS','Agatha Christie',21900,'novela policial clásica de misterio en un tren, detective Poirot'),
 ('EJ-032','Policial','DIEZ NEGRITOS','Agatha Christie',20900,'novela policial de misterio, diez invitados en una isla y un asesino'),
 ('EJ-033','Thriller','EL CÓDIGO DA VINCI','Dan Brown',32900,'thriller de conspiraciones, arte y símbolos religiosos'),
 ('EJ-034','Thriller','LA CHICA DEL TREN','Paula Hawkins',28900,'thriller psicológico narrado por tres mujeres'),
 ('EJ-035','Policial','LOS HOMBRES QUE NO AMABAN A LAS MUJERES','Stieg Larsson',34900,'novela negra nórdica con una hacker y un periodista'),
 ('EJ-036','Policial','ESTUDIO EN ESCARLATA','Arthur Conan Doyle',17900,'primera aventura de Sherlock Holmes, policial clásico'),
 ('EJ-037','Clásicos','CRIMEN Y CASTIGO','Fiódor Dostoievski',26900,'clásico ruso sobre culpa, moral y un crimen'),
 ('EJ-038','Clásicos','DON QUIJOTE DE LA MANCHA','Miguel de Cervantes',36900,'clásico de la literatura española, aventuras y humor'),
 ('EJ-039','Clásicos','ORGULLO Y PREJUICIO','Jane Austen',24900,'clásico romántico sobre amor, clases sociales y malentendidos'),
 ('EJ-040','Clásicos','CUMBRES BORRASCOSAS','Emily Brontë',21900,'clásico gótico sobre una pasión destructiva'),
 ('EJ-041','Romance','VERITY','Colleen Hoover',29900,'thriller romántico oscuro sobre una escritora y un manuscrito'),
 ('EJ-042','Romance','ROMPER EL CÍRCULO','Colleen Hoover',30900,'novela romántica sobre una relación abusiva y la decisión de salir'),
 ('EJ-043','Romance','UGLY LOVE','Colleen Hoover',28900,'novela romántica contemporánea de pareja sin compromiso'),
 ('EJ-044','Historia','SAPIENS','Yuval Noah Harari',38900,'historia de la humanidad desde sus orígenes, divulgación'),
 ('EJ-045','Historia','HOMO DEUS','Yuval Noah Harari',37900,'futuro de la humanidad, tecnología e inteligencia artificial'),
 ('EJ-046','Autoayuda','HÁBITOS ATÓMICOS','James Clear',33900,'cómo construir buenos hábitos y dejar los malos, productividad'),
 ('EJ-047','Psicología','EL HOMBRE EN BUSCA DE SENTIDO','Viktor Frankl',22900,'testimonio de un sobreviviente de campos de concentración y el sentido de la vida'),
 ('EJ-048','Finanzas','PADRE RICO, PADRE POBRE','Robert Kiyosaki',24900,'educación financiera, inversión e ingresos'),
 ('EJ-049','Autoayuda','EL PODER DEL AHORA','Eckhart Tolle',26900,'espiritualidad, ansiedad y vivir el presente'),
 ('EJ-050','Ciencia','BREVE HISTORIA DEL TIEMPO','Stephen Hawking',29900,'divulgación científica sobre el universo, agujeros negros y el tiempo'),
 ('EJ-051','Historia','ARMAS, GÉRMENES Y ACERO','Jared Diamond',36900,'por qué algunas civilizaciones dominaron a otras, historia y geografía'),
 ('EJ-052','Psicología','PENSAR RÁPIDO, PENSAR DESPACIO','Daniel Kahneman',39900,'psicología de las decisiones y los sesgos, economía del comportamiento'),
 ('EJ-053','Autoayuda','LOS CUATRO ACUERDOS','Miguel Ruiz',19900,'sabiduría tolteca, desarrollo personal'),
 ('EJ-054','Infantil','EL PRINCIPITO','Antoine de Saint-Exupéry',18900,'fábula poética sobre la amistad y lo esencial, para chicos y grandes'),
 ('EJ-055','Infantil','MATILDA','Roald Dahl',21900,'novela infantil sobre una nena genio con poderes y una directora malvada'),
 ('EJ-056','Infantil','CHARLIE Y LA FÁBRICA DE CHOCOLATE','Roald Dahl',21900,'novela infantil de aventura en una fábrica de golosinas'),
 ('EJ-057','Infantil','¿DÓNDE ESTÁ WALLY?','Martin Handford',25900,'libro de búsqueda con ilustraciones, juego para chicos'),
 ('EJ-058','Infantil','LA ORUGA HAMBRIENTA','Eric Carle',19900,'libro ilustrado para primeros lectores sobre una oruga y los días de la semana'),
 ('EJ-059','Infantil','ELMER','David McKee',17900,'cuento ilustrado sobre un elefante de colores y la diferencia'),
 ('EJ-060','Infantil','CUENTOS DE BUENAS NOCHES PARA NIÑAS REBELDES','Elena Favilli',36900,'biografías cortas de mujeres extraordinarias, para chicas y chicos'),
 ('EJ-061','Consulta','DICCIONARIO DE LA LENGUA ESPAÑOLA','Real Academia Española',52900,'diccionario de consulta, útil para el colegio y el trabajo'),
 ('EJ-062','Educativo','ATLAS GEOGRÁFICO ESCOLAR','Editorial Escolar',28900,'atlas con mapas físicos y políticos para el colegio'),
 ('EJ-063','Novela gráfica','MAUS','Art Spiegelman',39900,'novela gráfica sobre el Holocausto contado con ratones y gatos'),
 ('EJ-064','Novela gráfica','PERSÉPOLIS','Marjane Satrapi',33900,'novela gráfica autobiográfica sobre crecer en Irán'),
 ('EJ-065','Novela gráfica','WATCHMEN','Alan Moore',54900,'novela gráfica de superhéroes, adulta y política'),
 ('EJ-066','Manga','ONE PIECE 1','Eiichiro Oda',12900,'manga de aventuras de piratas, primer tomo'),
 ('EJ-067','Manga','NARUTO 1','Masashi Kishimoto',12900,'manga de ninjas y amistad, primer tomo'),
 ('EJ-068','Manga','DEATH NOTE 1','Tsugumi Ohba',13900,'manga de suspenso sobre un cuaderno que mata'),
 ('EJ-069','Ensayo','LAS VENAS ABIERTAS DE AMÉRICA LATINA','Eduardo Galeano',28900,'ensayo histórico sobre la explotación de América Latina'),
 ('EJ-070','Novela','LA SOMBRA DEL VIENTO','Carlos Ruiz Zafón',34900,'novela de misterio sobre un libro maldito y una librería de libros olvidados')
) AS v(sku, cat, nombre, autor, precio, descr) ON n.slug IN ('demo','rayuela');
