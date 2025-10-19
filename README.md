# Audit Service

Microservicio para capturar y almacenar todos los eventos del sistema de facturación electrónica FactuMarket S.A.

## ¿Qué hace?

Este servicio registra todas las operaciones que ocurren en el sistema:
- ✅ Operaciones de clientes (crear, leer, actualizar, eliminar)
- ✅ Operaciones de facturas (crear, leer, actualizar, eliminar)
- ✅ Errores del sistema
- ✅ Captura automática de IP, User-Agent y timestamps

## Tecnologías

- **Ruby** 3.2.2
- **Rails** 7.2.2 (API-only)
- **MongoDB** (base de datos NoSQL)
- **Docker** (para ejecutar fácilmente)

---

## 🚀 Inicio Rápido con Docker

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd audits-service
```

### 2. Crear las imágenes y levantar los contenedores
```bash
docker-compose up --build -d
```

Esto levanta:
- **MongoDB** en el puerto `27017`
- **API Rails** en el puerto `3002`

### 3. Cargar datos de prueba (primera vez)
```bash
docker-compose exec api rails db:seed
```

### 4. Verificar que funciona
```bash
curl http://localhost:3002/health
```

Deberías ver:
```json
{
  "status": "ok",
  "service": "audit-service",
  "database": "connected"
}
```

**¡Listo!** La API está corriendo en `http://localhost:3002`

---

## 🛠️ Comandos Útiles de Docker

### Ver logs en tiempo real
```bash
docker-compose logs -f api
```

### Detener los contenedores
```bash
docker-compose down
```

### Reiniciar los contenedores
```bash
docker-compose restart
```

### Ejecutar comandos dentro del contenedor
```bash
# Abrir consola de Rails
docker-compose exec api rails console

# Correr tests
docker-compose exec api rspec

# Ver eventos en la base de datos
docker-compose exec api rails runner "puts AuditEvent.count"
```

### Reconstruir las imágenes
```bash
docker-compose up --build
```

---

## 📡 Endpoints de la API

### Health Check
```bash
GET /health
```

### Crear un evento de auditoría
```bash
POST /api/v1/audit_events
Content-Type: application/json

{
  "audit_event": {
    "event_type": "client.created",
    "entity_type": "client",
    "entity_id": "CLI-001",
    "action": "create",
    "status": "success",
    "metadata": {
      "name": "ACME Corp",
      "email": "contact@acme.com"
    }
  }
}
```

### Listar eventos (con paginación y filtros)
```bash
# Todos los eventos
GET /api/v1/audit_events?page=1&per_page=10

# Filtrar por tipo de entidad
GET /api/v1/audit_events?entity_type=invoice

# Filtrar por tipo de evento
GET /api/v1/audit_events?event_type=client.created

# Filtrar por ID de entidad
GET /api/v1/audit_events?entity_id=CLI-001
```

### Obtener un evento específico
```bash
GET /api/v1/audit_events/:id
```

### Obtener todos los eventos de una entidad
```bash
GET /api/v1/audit_events/entity/CLI-001
```

---

## 📝 Ejemplos de Uso

### Usando cURL

```bash
# Health check
curl http://localhost:3002/health

# Crear evento de cliente
curl -X POST http://localhost:3002/api/v1/audit_events \
  -H "Content-Type: application/json" \
  -d '{
    "audit_event": {
      "event_type": "client.created",
      "entity_type": "client",
      "entity_id": "CLI-123",
      "action": "create",
      "status": "success",
      "metadata": {"name": "Test Client"}
    }
  }'

# Listar eventos con filtro
curl "http://localhost:3002/api/v1/audit_events?entity_type=client&per_page=5"

# Obtener eventos de una entidad específica
curl "http://localhost:3002/api/v1/audit_events/entity/CLI-123"
```

---

## 🧪 Testing

### Usando Docker (Recomendado)

**Script automatizado:**
```bash
# Ejecutar todos los tests
./bin/docker-test

# Ejecutar tests específicos
./bin/docker-test spec/models
./bin/docker-test spec/requests/health_spec.rb

# Con formato detallado
./bin/docker-test --format documentation
```

**Comando manual:**
```bash
# IMPORTANTE: Usar -e RAILS_ENV=test para ejecutar en modo test
docker-compose exec -T -e RAILS_ENV=test api rspec

# Con formato detallado
docker-compose exec -T -e RAILS_ENV=test api rspec --format documentation
```

### Localmente (Sin Docker)

```bash
# Ejecutar todos los tests
RAILS_ENV=test bundle exec rspec

# Con formato detallado
RAILS_ENV=test bundle exec rspec --format documentation
```

### Ver cobertura de tests
```bash
./bin/docker-test
# Luego abrir: coverage/index.html
```

### ⚠️ Nota Importante sobre Testing en Docker

Los tests **DEBEN** ejecutarse con `RAILS_ENV=test`. Si ejecutas:
```bash
# ❌ INCORRECTO - Correrá en modo development y fallará
docker-compose exec api rspec

# ✅ CORRECTO - Usa el script o la variable de entorno
./bin/docker-test
docker-compose exec -T -e RAILS_ENV=test api rspec
```

---

## 📊 Estructura de Datos

### Campos de un Evento de Auditoría

```javascript
{
  "id": "507f1f77bcf86cd799439011",
  "event_type": "client.created",      // Tipo de evento
  "entity_type": "client",              // client | invoice | system
  "entity_id": "CLI-001",               // ID de la entidad
  "action": "create",                   // create | read | update | delete | error
  "status": "success",                  // success | failed
  "metadata": {},                       // Datos adicionales (flexible)
  "user_agent": "Mozilla/5.0...",       // Capturado automáticamente
  "ip_address": "192.168.1.1",          // Capturado automáticamente
  "occurred_at": "2024-01-15T10:30:00Z",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

### Índices de MongoDB (optimización)

- `entity_id` ⚡
- `entity_type` ⚡
- `event_type` ⚡
- `occurred_at` (descendente) ⚡
- `created_at` (descendente) ⚡
- Compuesto: `entity_type` + `entity_id` ⚡

---

## ⚙️ Configuración (Avanzado)

### Variables de Entorno

Editar el archivo `.env` si necesitas cambiar la configuración:

```env
MONGODB_HOST=mongodb
MONGODB_PORT=27017
MONGODB_DATABASE=audit_service_development
RAILS_ENV=development
PORT=3002
```

### Ejecución sin Docker (desarrollo local)

Si prefieres correr sin Docker:

```bash
# 1. Instalar dependencias
bundle install

# 2. Asegurarse que MongoDB esté corriendo
brew services start mongodb-community  # macOS
# o
sudo systemctl start mongod           # Linux

# 3. Crear índices
rails db:mongoid:create_indexes

# 4. Cargar datos de prueba
rails db:seed

# 5. Iniciar servidor
rails server -p 3002
```

---

## 📖 Documentación Adicional

- **API_EXAMPLES.md**: Más ejemplos de uso de la API
- **QUICK_START.md**: Guía rápida de inicio
- **CLAUDE.md**: Guía para desarrollo con Claude

---

## 🔍 Troubleshooting

### El contenedor no inicia
```bash
# Ver logs para encontrar el error
docker-compose logs api
```

### No se conecta a MongoDB
```bash
# Verificar que MongoDB esté corriendo
docker-compose ps

# Reiniciar MongoDB
docker-compose restart mongodb
```

### Limpiar todo y empezar de cero
```bash
# Detener y eliminar contenedores y volúmenes
docker-compose down -v

# Reconstruir y levantar
docker-compose up --build -d
```

---

## 📞 Soporte

Para preguntas o problemas, contactar al equipo de desarrollo.

---

## 📄 Licencia

Propietario - FactuMarket S.A.
