-- Cada vez que el cliente entra por el link con el codigo (#sbs) empieza una conversacion nueva:
-- "inicio" cambia y con eso cambia la clave de memoria del asistente.
ALTER TABLE sesiones ADD COLUMN IF NOT EXISTS inicio TIMESTAMPTZ;
