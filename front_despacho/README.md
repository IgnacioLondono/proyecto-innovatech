# Frontend Despacho - React + Vite + Nginx

Interfaz web para la gestión de despachos de Innovatech Chile.

## Descripción

Frontend moderno construido con React y Vite, containerizado con Nginx. Comunica con los microservicios backend para operaciones en tiempo real.

## Stack Tecnológico

- **React 18+**: Interfaz de usuario reactiva
- **Vite**: Build tool ultra-rápido
- **Tailwind CSS**: Estilos utilitarios
- **Nginx**: Servidor web para producción (en contenedor)
- **Docker**: Containerización

## Inicio Rápido

### Desarrollo Local (sin Docker)

#### Requisitos
- Node.js 18+
- npm o yarn

#### Instalación

```bash
# 1. Instalar dependencias
npm install

# 2. Ejecutar servidor de desarrollo
npm run dev

# El frontend estará en http://localhost:5173
```

#### Build para Producción

```bash
# Compilar
npm run build

# Previewar build
npm run preview
```

## Con Docker

### Build de la imagen

```bash
# Desde la carpeta front_despacho/
docker build -t frontend-despacho:latest .
```

### Ejecutar contenedor

```bash
docker run -d \
  -p 3000:80 \
  --name frontend-despacho \
  frontend-despacho:latest

# Accesible en http://localhost:3000
```

### Con docker-compose (recomendado)

```bash
# Desde raíz del proyecto
docker-compose up -d frontend-despacho
```

## Estructura del Proyecto

```
front_despacho/
├── Dockerfile              # Multi-stage: build + nginx
├── nginx.conf             # Configuración de Nginx
├── README.md              # Este archivo
├── package.json           # Dependencias NPM
├── vite.config.js         # Configuración de Vite
├── tailwind.config.js     # Configuración de Tailwind
├── index.html             # HTML principal
├── src/
│   ├── main.jsx          # Punto de entrada React
│   ├── App.jsx           # Componente principal
│   ├── index.css         # Estilos globales
│   ├── componentes/      # Componentes reutilizables
│   │   ├── Header.jsx
│   │   ├── Footer.jsx
│   │   ├── DespachoForm.jsx
│   │   └── DespachoList.jsx
│   ├── Routes/           # Páginas/Rutas
│   │   ├── Home.jsx
│   │   ├── Despachos.jsx
│   │   └── NotFound.jsx
│   └── assets/           # Imágenes, logos, etc.
└── public/               # Archivos estáticos
```

## Configuración

### Variables de Entorno

Crear archivo `.env` en la raíz:

```env
VITE_API_URL=http://localhost:8081
VITE_API_VENTAS_URL=http://localhost:8082
VITE_APP_TITLE=Innovatech Chile
VITE_APP_VERSION=1.0.0
```

### En Docker

Las variables se pasan en `docker-compose.yml`:

```yaml
environment:
  VITE_API_URL: http://backend-despachos:8080
  VITE_API_VENTAS_URL: http://backend-ventas:8080
```

### Acceso a Variables en Componentes

```javascript
const API_URL = import.meta.env.VITE_API_URL;

export default function DespachoList() {
  const [despachos, setDespachos] = React.useState([]);

  React.useEffect(() => {
    fetch(`${API_URL}/api/despachos`)
      .then(res => res.json())
      .then(data => setDespachos(data));
  }, []);

  return (
    <div>
      {despachos.map(despacho => (
        <div key={despacho.id}>{despacho.nombre}</div>
      ))}
    </div>
  );
}
```

## Dockerfile Explicado

### Stage 1: Builder (Compilación)

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
```

- Usa `node:18-alpine` (imagen Node ligera)
- Instala dependencias con `npm ci` (más confiable que `npm install`)
- Compila con Vite
- Genera carpeta `dist/` con archivos estáticos

### Stage 2: Runtime (Nginx)

```dockerfile
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist .
COPY nginx.conf /etc/nginx/nginx.conf
USER nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

- Usa `nginx:alpine` (servidor web ligero)
- Copia archivos compilados a docroot de Nginx
- Copia configuración personalizada
- Ejecuta como usuario `nginx` (no root)
- Expone puerto 80

**Beneficios:**
- Imagen final: ~50MB (sin Node)
- Servicio optimizado para producción
- Más seguro (sin herramientas de desarrollo)

## Nginx Configuration

El archivo `nginx.conf` configura:

```nginx
# SPA Routing - todos los requests van a index.html
location / {
    try_files $uri $uri/ /index.html;
}

# Caché de assets
location ~* \.(js|css|png|jpg)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}

# Compresión
gzip on;
gzip_types text/plain text/css application/javascript;
```

Esto permite que React Router funcione correctamente en producción.

## Comunicación con Backend

### Fetch API

```javascript
// GET
async function getDespachos() {
  const response = await fetch(`${API_URL}/api/despachos`);
  return response.json();
}

// POST
async function crearDespacho(data) {
  const response = await fetch(`${API_URL}/api/despachos`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  return response.json();
}
```

### Con librería (axios, etc.)

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
});

export const despachoService = {
  getAll: () => api.get('/api/despachos'),
  create: (data) => api.post('/api/despachos', data),
  update: (id, data) => api.put(`/api/despachos/${id}`, data),
  delete: (id) => api.delete(`/api/despachos/${id}`)
};
```

## Dependencias Principales

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.x.x"
  },
  "devDependencies": {
    "vite": "^4.x.x",
    "@vitejs/plugin-react": "^4.x.x",
    "tailwindcss": "^3.x.x",
    "postcss": "^8.x.x",
    "autoprefixer": "^10.x.x"
  }
}
```

## Testing

### Componentes

```bash
# Instalar testing library
npm install --save-dev @testing-library/react @testing-library/jest-dom vitest

# Ejecutar tests
npm test
```

Ejemplo de test:

```javascript
import { render, screen } from '@testing-library/react';
import DespachoList from './DespachoList';

test('muestra lista de despachos', () => {
  render(<DespachoList />);
  expect(screen.getByText(/despachos/i)).toBeInTheDocument();
});
```

## Solución de Problemas

### Error: Backend responde pero Frontend no ve los datos

**Problema CORS:**
```
Access to XMLHttpRequest blocked by CORS policy
```

**Solución en Backend:**
```properties
spring.web.allow-cors=true
```

O en Java:
```java
@Configuration
public class CorsConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("*")
                    .allowedMethods("*");
            }
        };
    }
}
```

### Error: Build falla con "out of memory"

```bash
# Aumentar memoria de Node
NODE_OPTIONS=--max-old-space-size=4096 npm run build
```

### Frontend no se conecta a Backend en Docker

**Problema:** URL del backend incorrecto

**Solución:**
- En desarrollo local: `http://localhost:8081`
- En Docker: `http://backend-despachos:8080` (nombre del servicio)

Verificar en `docker-compose.yml`:
```yaml
frontend-despacho:
  environment:
    VITE_API_URL: http://backend-despachos:8080
```

## Scripts NPM

```bash
# Desarrollo
npm run dev              # Iniciar servidor Vite

# Build
npm run build           # Compilar para producción
npm run preview         # Preview del build

# Testing
npm test               # Ejecutar tests
npm run test:ui        # UI de tests

# Linting
npm run lint           # Verificar código
npm run lint:fix       # Arreglar automáticamente

# Docker
docker build -t frontend-despacho:latest .
docker run -d -p 3000:80 frontend-despacho:latest
```

## Seguridad

### Validación de Entrada

```javascript
function validarDespacho(data) {
  if (!data.nombre || data.nombre.trim().length === 0) {
    throw new Error('El nombre es requerido');
  }
  if (!/^[a-zA-Z0-9\s]*$/.test(data.nombre)) {
    throw new Error('Caracteres inválidos');
  }
  return true;
}
```

### Sanitización de HTML

```javascript
import DOMPurify from 'dompurify';

function renderHTML(html) {
  const clean = DOMPurify.sanitize(html);
  return <div dangerouslySetInnerHTML={{ __html: clean }} />;
}
```

### Headers de Seguridad (Nginx)

```nginx
add_header X-Content-Type-Options "nosniff";
add_header X-Frame-Options "DENY";
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

## Performance

### Optimización de Build

```javascript
// vite.config.js
export default {
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom']
        }
      }
    },
    minify: 'terser'
  }
};
```

### Code Splitting

```javascript
// Lazy loading de componentes
import { lazy, Suspense } from 'react';

const DespachoList = lazy(() => import('./pages/DespachoList'));

export default function App() {
  return (
    <Suspense fallback={<div>Cargando...</div>}>
      <DespachoList />
    </Suspense>
  );
}
```

## Referencias

- [React Documentation](https://react.dev)
- [Vite Guide](https://vitejs.dev)
- [Tailwind CSS](https://tailwindcss.com)
- [Nginx Documentation](https://nginx.org)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## Conceptos Clave

### React
- Componentes funcionales con Hooks
- Context API para estado global
- React Router para navegación

### Vite
- Hot Module Replacement (HMR)
- Native ES modules
- Optimización automática

### Docker
- Multi-stage build
- Nginx como servidor
- Volúmenes para desarrollo

## Desarrollador

**Responsable del Frontend:**
- Interfaz de usuario
- Comunicación con APIs
- Dockerización con Nginx

## Historial de Cambios

### v1.0 (Mayo 2026)
- Setup React + Vite
- Componentes básicos
- Dockerfile multi-stage
- Integración con Backends
- Documentación completa

---

**Última actualización**: Mayo 2026
**Versión**: 1.0