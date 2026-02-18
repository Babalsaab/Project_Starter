```skill
# API Contract Validation

When designing, reviewing, or consuming APIs, enforce these standards:

## REST API Conventions

### URL Design
- Use plural nouns for resources: `/users`, `/orders`, `/products`
- Use path params for identity: `/users/{id}`
- Use query params for filtering: `/users?role=admin&status=active`
- Nest for relationships: `/users/{id}/orders` (max 2 levels deep)
- Use kebab-case for multi-word paths: `/order-items`
- Version in URL path: `/api/v1/users` or via `Accept` header

### HTTP Methods
| Method | Purpose | Idempotent | Response |
|--------|---------|------------|----------|
| GET | Read resource(s) | Yes | 200 + body |
| POST | Create resource | No | 201 + Location header |
| PUT | Full replace | Yes | 200 + body |
| PATCH | Partial update | No | 200 + body |
| DELETE | Remove resource | Yes | 204 (no body) |

### Status Codes
- **2xx**: 200 OK, 201 Created, 204 No Content
- **3xx**: 301/302 Redirect (only for URL changes)
- **4xx**: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 422 Unprocessable Entity, 429 Too Many Requests
- **5xx**: 500 Internal Server Error, 503 Service Unavailable

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description",
    "details": [
      { "field": "email", "issue": "Invalid email format" }
    ],
    "request_id": "req_abc123"
  }
}
```

## Naming Conventions

- Request/response fields: `camelCase`
- Consistent naming: if `created_at` exists, don't introduce `updatedTime`
- Boolean fields prefixed: `isActive`, `hasOrders`, `canEdit`
- Date/time fields: ISO 8601 format (`2024-01-15T10:30:00Z`)
- Enum values: `UPPER_SNAKE_CASE`

## Pagination

Always paginate list endpoints:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8,
    "has_next": true,
    "has_prev": false
  }
}
```

Prefer cursor-based for large datasets:
```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTAwfQ==",
    "has_more": true
  }
}
```

## Versioning & Backward Compatibility

### Breaking Changes (NEVER in minor version)
- Removing a field from response
- Renaming a field
- Changing a field's type
- Removing an endpoint
- Adding required request fields

### Non-Breaking Changes (safe in minor version)
- Adding optional request fields
- Adding response fields
- Adding new endpoints
- Adding new enum values (if client handles unknown)

### Deprecation Process
1. Add `Deprecation` header with sunset date
2. Document replacement in API docs
3. Log usage of deprecated endpoints
4. Remove after sunset date (major version bump)

## Security

- Require authentication on all mutating endpoints
- Rate limit all endpoints (especially auth)
- Validate and sanitize all input
- Never expose internal IDs or stack traces
- Use HTTPS only — reject HTTP
- Include request ID in all responses for tracing

## Output Format

```
## API Contract Report

### Compliance: [PASS | WARNINGS | VIOLATIONS]

### Endpoints Reviewed
| Endpoint | Method | Issues |
|----------|--------|--------|
| /api/v1/users | GET | 0 |
| /api/v1/users | POST | 2 |

### Violations
| # | Severity | Rule | Endpoint | Description | Fix |
|---|----------|------|----------|-------------|-----|
| 1 | HIGH | Error Format | POST /users | Non-standard error body | Use standard error envelope |

### Breaking Changes Detected
- [ ] None / [ ] List...

### Recommendations
1. ...
```
```
