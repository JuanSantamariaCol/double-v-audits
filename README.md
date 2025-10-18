# Audit Service

A microservice for capturing and storing all system events in the FactuMarket electronic invoicing system. This service is part of a three-microservice architecture (Clients, Invoices, Audit).

## Overview

The Audit Service provides a centralized event logging system that captures:
- Client operations (create, read, update, delete)
- Invoice operations (create, read, update, delete)
- System errors and exceptions
- Request metadata (IP address, user agent, timestamps)

## Tech Stack

- **Ruby**: 3.2.2
- **Rails**: 7.2.2 (API-only mode)
- **Database**: MongoDB with Mongoid ODM
- **Web Server**: Puma
- **Testing**: RSpec, FactoryBot, SimpleCov
- **Containerization**: Docker & Docker Compose

## Architecture

This service follows standard Rails MVC architecture with:
- RESTful API endpoints
- Mongoid for MongoDB integration
- JSON API serialization
- Pagination with Pagy
- Comprehensive error handling
- CORS configuration for cross-origin requests

## Prerequisites

- Ruby 3.2.2
- MongoDB 7.0+
- Docker & Docker Compose (optional, for containerized setup)

## Getting Started

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd audits-service
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Configure environment variables**

   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

   Update `.env` with your configuration:
   ```env
   MONGODB_HOST=localhost
   MONGODB_PORT=27017
   MONGODB_DATABASE=audit_service_development
   RAILS_ENV=development
   PORT=3002
   ```

4. **Start MongoDB**

   Make sure MongoDB is running on your system:
   ```bash
   # macOS (using Homebrew)
   brew services start mongodb-community

   # Linux
   sudo systemctl start mongod

   # Or use Docker
   docker run -d -p 27017:27017 --name mongodb mongo:7.0
   ```

5. **Create MongoDB indexes**
   ```bash
   rails db:mongoid:create_indexes
   ```

6. **Load seed data**
   ```bash
   rails db:seed
   ```

7. **Start the server**
   ```bash
   rails server -p 3002
   ```

   The API will be available at `http://localhost:3002`

### Docker Setup (Recommended)

1. **Start all services with Docker Compose**
   ```bash
   docker-compose up -d
   ```

   This will start:
   - MongoDB on port 27017
   - Rails API on port 3002

2. **Load seed data (first time only)**
   ```bash
   docker-compose exec api rails db:seed
   ```

3. **View logs**
   ```bash
   docker-compose logs -f api
   ```

4. **Stop services**
   ```bash
   docker-compose down
   ```

## API Endpoints

### Health Check

**GET** `/health`

Check service health and database connectivity.

**Response:**
```json
{
  "status": "ok",
  "service": "audit-service",
  "timestamp": "2024-01-15T10:30:00Z",
  "database": "connected"
}
```

### Audit Events

#### Create Audit Event

**POST** `/api/v1/audit_events`

Create a new audit event.

**Request Body:**
```json
{
  "audit_event": {
    "event_type": "invoice.created",
    "entity_type": "invoice",
    "entity_id": "INV-123",
    "action": "create",
    "status": "success",
    "metadata": {
      "amount": 1000.50,
      "client_id": "CLI-456"
    }
  }
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "event_type": "invoice.created",
    "entity_type": "invoice",
    "entity_id": "INV-123",
    "action": "create",
    "status": "success",
    "metadata": {
      "amount": 1000.50,
      "client_id": "CLI-456"
    },
    "user_agent": "Mozilla/5.0...",
    "ip_address": "192.168.1.1",
    "occurred_at": "2024-01-15T10:30:00Z",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Get Single Audit Event

**GET** `/api/v1/audit_events/:id`

Retrieve a specific audit event by ID.

**Response:** `200 OK`

#### List Audit Events

**GET** `/api/v1/audit_events`

List all audit events with filtering and pagination.

**Query Parameters:**
- `page` (integer): Page number (default: 1)
- `per_page` (integer): Items per page (default: 25)
- `entity_id` (string): Filter by entity ID
- `entity_type` (string): Filter by entity type (client, invoice, system)
- `event_type` (string): Filter by event type
- `start_date` (datetime): Start of date range
- `end_date` (datetime): End of date range

**Example:**
```bash
GET /api/v1/audit_events?entity_type=invoice&page=1&per_page=10
```

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "event_type": "invoice.created",
      "entity_type": "invoice",
      "entity_id": "INV-123",
      ...
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 125,
    "per_page": 25
  }
}
```

#### Get Events by Entity

**GET** `/api/v1/audit_events/entity/:entity_id`

Retrieve all audit events for a specific entity.

**Query Parameters:**
- `entity_type` (string, optional): Filter by entity type
- `page` (integer): Page number
- `per_page` (integer): Items per page

**Example:**
```bash
GET /api/v1/audit_events/entity/INV-123?entity_type=invoice
```

## Database Schema

### AuditEvent Collection

```javascript
{
  "_id": ObjectId,
  "event_type": String,      // "client.created", "invoice.read", etc.
  "entity_type": String,     // "client" | "invoice" | "system"
  "entity_id": String,       // ID of related entity
  "action": String,          // "create" | "read" | "update" | "delete" | "error"
  "status": String,          // "success" | "failed"
  "metadata": Object,        // Flexible field for additional context
  "user_agent": String,
  "ip_address": String,
  "occurred_at": DateTime,
  "created_at": DateTime,
  "updated_at": DateTime
}
```

### Indexes

- `entity_id` (ascending)
- `entity_type` (ascending)
- `event_type` (ascending)
- `occurred_at` (descending)
- `created_at` (descending)
- Compound: `entity_type` + `entity_id`

## Testing

### Run all tests

```bash
rspec
```

### Run specific test files

```bash
# Model tests
rspec spec/models/audit_event_spec.rb

# Request tests
rspec spec/requests/api/v1/audit_events_spec.rb

# With coverage report
COVERAGE=true rspec
```

### Test coverage

SimpleCov generates coverage reports in `coverage/index.html`

## API Usage Examples

### Using cURL

```bash
# Health check
curl http://localhost:3002/health

# Create audit event
curl -X POST http://localhost:3002/api/v1/audit_events \
  -H "Content-Type: application/json" \
  -d '{
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
  }'

# List audit events
curl "http://localhost:3002/api/v1/audit_events?page=1&per_page=10"

# Filter by entity type
curl "http://localhost:3002/api/v1/audit_events?entity_type=invoice"

# Get events by entity
curl "http://localhost:3002/api/v1/audit_events/entity/CLI-001"

# Filter by date range
curl "http://localhost:3002/api/v1/audit_events?start_date=2024-01-01T00:00:00Z&end_date=2024-01-31T23:59:59Z"
```

### Using HTTPie

```bash
# Create audit event
http POST localhost:3002/api/v1/audit_events \
  audit_event:='{
    "event_type": "invoice.updated",
    "entity_type": "invoice",
    "entity_id": "INV-456",
    "action": "update",
    "status": "success",
    "metadata": {"status": "paid"}
  }'

# List with filters
http GET localhost:3002/api/v1/audit_events \
  entity_type==client \
  page==1 \
  per_page==20
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MONGODB_HOST` | MongoDB host | localhost | Yes |
| `MONGODB_PORT` | MongoDB port | 27017 | Yes |
| `MONGODB_DATABASE` | Database name | audit_service_development | Yes |
| `RAILS_ENV` | Rails environment | development | Yes |
| `PORT` | Server port | 3002 | Yes |

## Error Handling

The API returns consistent error responses:

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Document not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Validation Error",
  "message": "Failed to create audit event",
  "details": [
    "Event type can't be blank",
    "Entity type is not included in the list"
  ]
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

## Development

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -A

# Security audit
bundle exec brakeman
```

### Console

```bash
# Local
rails console

# Docker
docker-compose exec api rails console
```

### Database

```bash
# Drop database
rails db:mongoid:drop

# Create indexes
rails db:mongoid:create_indexes

# Remove indexes
rails db:mongoid:remove_indexes
```

## Production Deployment

### Using Kamal

The service includes Kamal configuration for deployment:

```bash
kamal setup
kamal deploy
```

### Environment Configuration

Ensure these environment variables are set in production:

- `MONGODB_HOST`
- `MONGODB_PORT`
- `MONGODB_DATABASE`
- `RAILS_MASTER_KEY` (for encrypted credentials)

### Performance Considerations

1. **Indexes**: All indexes are automatically created on first deployment
2. **Connection Pooling**: MongoDB connection pool size configured per environment
3. **Pagination**: Default 25 items per page, configurable via query params
4. **Horizontal Scaling**: Service is stateless and can be scaled horizontally

## Monitoring

### Health Checks

The `/health` endpoint provides:
- Service status
- Database connectivity
- Current timestamp

Use this endpoint for:
- Load balancer health checks
- Kubernetes liveness/readiness probes
- Monitoring systems

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `rspec`
4. Run linter: `rubocop`
5. Submit a pull request

## License

Proprietary - FactuMarket S.A.

## Support

For issues or questions, contact the development team.
