# Leonardo

Bot asistente comercial con IA para librerías, por WhatsApp — demo construida sobre el catálogo real de Yenny-El Ateneo. Producto: **Leonardo**.

## Estructura

- `scraping/` — scripts PowerShell que extraen el catálogo real del sitio (música, más vendidos, libros por categoría) vía los bloques `ld+json` embebidos en cada página, y los CSV resultantes.
- `db/` — esquema de Postgres (`schema.sql`) y los seeds SQL: catálogo de productos (`seed_productos.sql`, `seed_libros.sql`) y sucursales (`sucursales.sql`).
- `n8n/` — definición del workflow del AI Agent (`workflow_agent.json`): Chat Trigger + Claude + memoria + dos tools (Postgres catálogo y sucursales).
- `landing/` — landing page del producto (`index.html`), publicada como Claude Artifact.

## Infraestructura

- **n8n** self-hosted en Railway (`n8n-production-63d6.up.railway.app`), mismo proyecto que el Postgres del catálogo (conectados por red privada de Railway).
- **Postgres** en Railway — tablas `productos` y `sucursales`.
- **Claude (Anthropic)** como modelo del AI Agent.
- **WhatsApp Business Cloud API** — pendiente de activar el número de producción (bloqueado por verificación del chip al momento de este commit).

## Pendiente

- Activar y verificar el número de WhatsApp de producción, y swapear el trigger del workflow principal de Chat Trigger a WhatsApp Trigger.
- Confirmar si el WABA queda compartido con otros clientes (AgroTabaco) o se separa a uno propio.
