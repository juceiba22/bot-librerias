// Nodo "Definir perfil" (Code): junta el tipo de cliente que ya tenia la sesion con el que recien clasifico el bot.
// Si el negocio tiene varios tipos de cliente y todavia no sabemos cual es, marca "preguntar".
const base = $('Resolver negocio').first().json;
const perfiles = $('Cargar perfiles').first().json.perfiles || [];

let codigo = base.perfil_codigo || null;
try {
  // este nodo solo corrio si hubo que clasificar
  const g = $('Guardar perfil').first().json;
  if (g && g.perfil_codigo) codigo = g.perfil_codigo;
} catch (e) { /* no se clasifico en este mensaje */ }

const perfil = perfiles.find(p => p.codigo === codigo) || null;
return [{ json: { perfil, perfiles, preguntar: perfiles.length > 1 && !perfil } }];
