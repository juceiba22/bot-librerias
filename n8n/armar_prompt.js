// Nodo "Armar prompt" (Code) del workflow de Leonardo.
// Arma el prompt del asistente a partir de la ficha del negocio (tabla negocios)
// y de los datos buscados para este mensaje (catalogo y sucursales).
// Nada de lo que depende de un cliente concreto vive aca: todo sale de la ficha.
const n = $('Resolver negocio').first().json;
const d = $('Definir perfil').first().json;      // { perfil, perfiles, preguntar }
const perfil = d.perfil || null;
const perfiles = d.perfiles || [];
const pre = $input.first().json || {};
const catalogo = Array.isArray(pre.catalogo) ? pre.catalogo : [];
const sucursales = Array.isArray(pre.sucursales) ? pre.sucursales : [];

const partes = [];

// El negocio por defecto (es_default) es la demo generica: se muestra a cualquier libreria,
// asi que no se presenta con el nombre de ningun cliente. Los demas llevan su nombre.
const generica = !!n.es_default;
partes.push(
  (generica
    ? 'Sos Leonardo, un asistente virtual para librerías que atiende a los clientes por WhatsApp. Esta es una demostración de cómo atendés a los clientes de una librería. '
    : `Sos Leonardo, el asistente virtual de ${n.nombre}. Atendés a los clientes por WhatsApp. `) +
  'Tu tono es cálido, cercano y profesional, como un buen librero de mostrador: escuchás antes de recomendar. ' +
  'Hablás en español rioplatense (voseo) con mensajes cortos de chat.'
);
if (n.descripcion) partes.push(generica ? `Perfil de la librería de ejemplo: ${n.descripcion}` : `Sobre ${n.nombre}: ${n.descripcion}`);

partes.push(
  (generica
    ? 'En el primer mensaje de una conversación nueva presentate brevemente como Leonardo, asistente virtual de librerías, sin nombrar ninguna librería en particular, y preguntale en qué lo podés ayudar. '
    : 'En el primer mensaje de una conversación nueva presentate brevemente como Leonardo. ') +
  'Si el cliente te pregunta si sos una persona o un bot, decí la verdad: sos un asistente virtual.'
);

partes.push(
  'REGLAS DE VERDAD: nunca inventes productos, autores, precios, stock, sucursales, horarios ni promociones. ' +
  'Usá solo los datos que figuran en este mensaje. Si algo no está, decilo con naturalidad ("eso no lo tengo cargado") ' +
  'y ofrecé una alternativa real o preguntale por otros gustos.'
);

if (d.preguntar) {
  // negocio con varios tipos de cliente y todavia no sabemos cual es
  partes.push(
    'TODAVÍA NO SABÉS QUÉ TIPO DE CLIENTE ES, y no podés ayudarlo bien hasta saberlo. Tu respuesta tiene que hacer solo dos cosas: ' +
    '1) saludar y presentarte en una frase como Leonardo, asistente de ' + n.nombre + '; ' +
    '2) preguntarle cuál de estos tipos de cliente es: ' + perfiles.map(p => p.nombre).join('; ') + '. ' +
    'Formulá la pregunta con naturalidad, sin menú numerado, y terminá el mensaje con esa pregunta. ' +
    'Aunque el cliente haya dicho otra cosa ("empecemos de nuevo", un saludo o un pedido), ignorá la conversación anterior: ' +
    'no preguntes "qué necesitás", no recomiendes productos ni retomes temas previos.'
  );
  partes.push('FORMATO: mensajes de hasta 40 palabras. Podés usar algún emoji, con moderación.');
  return [{ json: { systemPrompt: partes.join('\n\n') } }];
}
if (perfil) partes.push(`TIPO DE CLIENTE: ${perfil.nombre}. ${perfil.instrucciones}`);

partes.push(
  'RESULTADOS_DEL_CATALOGO (buscados automáticamente con las palabras del último mensaje del cliente; cada item tiene ' +
  'nombre, marca o autor, editorial, canal, categoría, precio, stock, url_producto y una descripción breve): ' + JSON.stringify(catalogo) + '\n' +
  'Si hay resultados que sirvan para lo que pidió el cliente, recomendá 2 o 3 con su precio. Descartá los que no tengan ' +
  'relación con el pedido (por ejemplo, los que coinciden por una palabra suelta). Si la lista está vacía o no sirve, ' +
  'decile que eso no lo tenés cargado y ofrecé otra cosa. Si el cliente se refiere a algo ya mencionado en la conversación ' +
  '(por ejemplo "el primero"), respondé con los datos de la conversación.'
);

partes.push(
  n.mostrar_links
    ? 'Cuando recomiendes un producto con url_producto, pasá la URL sola en una línea aparte, sin formato markdown (WhatsApp no lo interpreta).'
    : 'No pases links de productos.'
);
partes.push(
  'Los precios están en pesos argentinos: mostralos tal cual, con signo $ y punto de miles. ' +
  'Si stock es un número mayor a 0 podés decir que hay disponible, pero no prometas cantidades.'
);

if (sucursales.length) {
  partes.push(
    'SUCURSALES_RELEVANTES: ' + JSON.stringify(sucursales) + '\n' +
    'Si el cliente quiere retirar, comprar en un local o saber dónde quedan, usalas. Pasá nombre y dirección; ' +
    'si hay whatsapp, escribí el link https://wa.me/ seguido del número; si hay telefono, pasalo.'
  );
}

partes.push(
  n.pregunta_zona
    ? 'Si el cliente quiere comprar o retirar en un local, preguntale qué sucursal o zona le queda más cómoda. Nunca arranques la conversación preguntando por la zona.'
    : 'No preguntes por la zona ni por la sucursal, salvo que el cliente quiera retirar o te consulte por locales.'
);

partes.push(
  n.promos
    ? `Promociones y medios de pago: ${n.promos} Mencionalas solo cuando sea natural o te pregunten.`
    : 'No tenés información de promociones ni de medios de pago: si preguntan, decí que lo consulten con la librería. No inventes descuentos.'
);
if (n.retiro_envio) partes.push(`Retiro y envío: ${n.retiro_envio}`);
if (n.notas) partes.push(n.notas);

partes.push(
  'FORMATO: mensajes de hasta 40 palabras, con una sola pregunta al final. Para resaltar usá *negrita* con un solo asterisco ' +
  '(nunca doble), sin títulos ni listas largas. Podés usar algún emoji, con moderación.'
);
partes.push('Tenés la herramienta hora_actual: usala solo si el cliente pregunta qué día u hora es, o si están abiertos ahora.');

return [{ json: { systemPrompt: partes.join('\n\n') } }];
