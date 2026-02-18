# Global Error Knowledge Base (GEKB) - API Documentation

**Document Version:** 1.0  
**Last Updated:** August 19, 2025  
**Document Type:** API Reference & Integration Guide  
**Dependencies:** GEKB PRD, Task Breakdown  
**Author:** Dr. Elena Vasquez (Senior Site Reliability Engineer & Knowledge Architect)  
**Project:** Global Error Knowledge Base System API  

---

## 📋 **API Overview**

### **Base URL**
```
Production: https://api.gekb.company.com/v1
Staging: https://api-staging.gekb.company.com/v1
Development: http://localhost:8000/v1
```

### **Authentication**
```http
Authorization: Bearer {jwt_token}
X-API-Key: {api_key}
X-Project-ID: {project_identifier}
```

### **API Versioning**
- **Current Version**: v1
- **Version Strategy**: URL path versioning (`/v1/`, `/v2/`)
- **Deprecation Policy**: 12 months notice for major version changes
- **Backward Compatibility**: Maintained within major versions

### **Rate Limiting**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1692441600
```

**Rate Limits by Endpoint:**
- Error Submission: 100 requests/minute
- Pattern Query: 500 requests/minute
- Analytics: 200 requests/minute
- Admin Operations: 50 requests/minute

### **Response Format**
```json
{
  "success": true,
  "data": {},
  "metadata": {
    "timestamp": "2025-08-19T14:32:15.000Z",
    "version": "1.0",
    "request_id": "req_abc123def456"
  },
  "errors": []
}
```

---

## 🚨 **Error Submission API**

### **Submit Error Event**
**Endpoint:** `POST /errors`  
**Purpose:** Submit a new error event to the knowledge base  
**Rate Limit:** 100 requests/minute  

#### **Request Headers**
```http
Content-Type: application/json
Authorization: Bearer {jwt_token}
X-Project-ID: {project_id}
X-Agent-Type: {agent_type}
X-Environment: {environment}
```

#### **Request Body**
```json
{
  "error": {
    "message": "Cannot resolve module '@/components/ui/button'",
    "type": "ModuleNotFoundError",
    "category": "dependency_missing",
    "severity": "medium",
    "stackTrace": [
      "at resolveModule (webpack://./src/components/Dashboard.tsx:12:5)",
      "at ModuleResolver.resolve (webpack://./node_modules/webpack/lib/resolve.js:201:3)"
    ],
    "affectedFiles": [
      "src/components/Dashboard.tsx"
    ],
    "technology": {
      "framework": "nextjs",
      "library": "shadcn-ui",
      "component": "button",
      "version": "14.0.0"
    }
  },
  "context": {
    "userAction": "component_import",
    "featureBeingWorked": "dashboard_layout",
    "sessionId": "session_xyz789",
    "previousErrors": [],
    "relatedFiles": [
      "src/components/Dashboard.tsx",
      "components.json"
    ]
  },
  "agent": {
    "type": "frontend-development",
    "version": "2.1.4",
    "persona": "React Development Specialist",
    "sessionId": "agent_session_456"
  },
  "environment": {
    "type": "development",
    "nodeVersion": "18.17.0",
    "packageManager": "npm",
    "framework": "nextjs",
    "os": "darwin"
  },
  "project": {
    "name": "ai-dashboard-v2",
    "repository": "github.com/company/ai-dashboard-v2",
    "branch": "feature/dashboard-components",
    "commit": "a7b3c9d2e5f8",
    "version": "1.2.0"
  }
}
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "errorId": "gekb-2025-0819-1432-1247",
    "status": "processed",
    "processingTime": 2.34,
    "patternMatches": [
      {
        "patternId": "shadcn-missing-component",
        "confidence": 0.95,
        "occurrences": 23
      }
    ],
    "resolution": {
      "strategy": "dependency_installation",
      "automated": true,
      "success": true,
      "steps": [
        {
          "action": "install_shadcn_component",
          "command": "npx shadcn-ui@latest add button",
          "result": "success"
        }
      ]
    },
    "prevention": {
      "preventable": true,
      "methods": ["pre_commit_hook", "dependency_scanner"]
    }
  },
  "metadata": {
    "timestamp": "2025-08-19T14:32:15.000Z",
    "version": "1.0",
    "request_id": "req_err_submit_001"
  }
}
```

#### **Error Responses**
```json
// 400 Bad Request - Invalid error data
{
  "success": false,
  "errors": [
    {
      "code": "INVALID_ERROR_DATA",
      "message": "Missing required field: error.message",
      "field": "error.message"
    }
  ]
}

// 429 Too Many Requests
{
  "success": false,
  "errors": [
    {
      "code": "RATE_LIMIT_EXCEEDED",
      "message": "Rate limit exceeded. Try again in 60 seconds.",
      "retryAfter": 60
    }
  ]
}
```

### **Bulk Error Submission**
**Endpoint:** `POST /errors/bulk`  
**Purpose:** Submit multiple error events in a single request  
**Rate Limit:** 20 requests/minute  

#### **Request Body**
```json
{
  "errors": [
    {
      "error": { /* Error object 1 */ },
      "context": { /* Context object 1 */ },
      "agent": { /* Agent object 1 */ }
    },
    {
      "error": { /* Error object 2 */ },
      "context": { /* Context object 2 */ },
      "agent": { /* Agent object 2 */ }
    }
  ],
  "batchId": "batch_abc123",
  "processingMode": "async"
}
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "batchId": "batch_abc123",
    "totalErrors": 2,
    "processed": 2,
    "failed": 0,
    "results": [
      {
        "index": 0,
        "errorId": "gekb-2025-0819-1433-1248",
        "status": "processed"
      },
      {
        "index": 1,
        "errorId": "gekb-2025-0819-1433-1249",
        "status": "processed"
      }
    ]
  }
}
```

---

## 🔍 **Pattern Query API**

### **Search Patterns**
**Endpoint:** `GET /patterns/search`  
**Purpose:** Search for error patterns based on criteria  
**Rate Limit:** 500 requests/minute  

#### **Query Parameters**
```
?query=string              # Text search in pattern descriptions
&category=string           # Filter by error category
&technology=string         # Filter by technology stack
&severity=string           # Filter by severity level
&success_rate_min=float    # Minimum resolution success rate
&occurrences_min=int       # Minimum occurrence count
&limit=int                 # Number of results (default: 20, max: 100)
&offset=int                # Pagination offset
&sort_by=string            # Sort field (occurrences, success_rate, last_seen)
&sort_order=string         # Sort order (asc, desc)
```

#### **Example Request**
```http
GET /patterns/search?category=dependency_missing&technology=shadcn-ui&limit=10
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "patterns": [
      {
        "patternId": "shadcn-missing-component",
        "name": "Shadcn UI Component Missing",
        "description": "Error occurs when importing Shadcn UI component that hasn't been installed",
        "category": "dependency_missing",
        "technology": {
          "framework": "nextjs",
          "library": "shadcn-ui"
        },
        "occurrences": 23,
        "successRate": 0.95,
        "lastSeen": "2025-08-19T14:30:00.000Z",
        "resolution": {
          "strategy": "dependency_installation",
          "estimatedTime": 120,
          "steps": [
            {
              "action": "install_component",
              "command": "npx shadcn-ui@latest add {component}",
              "validation": "component_exists"
            }
          ]
        }
      }
    ],
    "pagination": {
      "total": 1,
      "limit": 10,
      "offset": 0,
      "hasMore": false
    }
  }
}
```

### **Get Pattern Details**
**Endpoint:** `GET /patterns/{pattern_id}`  
**Purpose:** Get detailed information about a specific pattern  

#### **Response**
```json
{
  "success": true,
  "data": {
    "pattern": {
      "patternId": "shadcn-missing-component",
      "name": "Shadcn UI Component Missing",
      "description": "Error occurs when importing Shadcn UI component that hasn't been installed",
      "category": "dependency_missing",
      "matchingCriteria": {
        "errorMessage": {
          "contains": ["Cannot resolve module", "@/components/ui/"],
          "regex": "Cannot resolve module '@/components/ui/\\w+'"
        },
        "technology": {
          "library": "shadcn-ui"
        },
        "files": {
          "patterns": ["*.tsx", "*.jsx"]
        }
      },
      "resolution": {
        "strategy": "dependency_installation",
        "confidence": 0.95,
        "estimatedTime": 120,
        "steps": [
          {
            "action": "verify_shadcn_config",
            "command": "cat components.json",
            "validation": "file_exists"
          },
          {
            "action": "install_component",
            "command": "npx shadcn-ui@latest add {component}",
            "validation": "component_exists"
          }
        ]
      },
      "statistics": {
        "occurrences": 23,
        "successRate": 0.95,
        "averageResolutionTime": 118.5,
        "firstSeen": "2025-07-15T10:20:00.000Z",
        "lastSeen": "2025-08-19T14:30:00.000Z",
        "projectsAffected": ["ai-dashboard-v2", "admin-portal", "user-app"]
      },
      "evolution": {
        "versions": [
          {
            "version": "1.0",
            "created": "2025-07-15T10:20:00.000Z",
            "changes": "Initial pattern creation"
          },
          {
            "version": "1.1",
            "created": "2025-08-01T09:15:00.000Z",
            "changes": "Updated resolution steps for new Shadcn CLI"
          }
        ]
      }
    }
  }
}
```

### **Pattern Matching**
**Endpoint:** `POST /patterns/match`  
**Purpose:** Find matching patterns for given error data  

#### **Request Body**
```json
{
  "error": {
    "message": "Cannot resolve module '@/components/ui/card'",
    "type": "ModuleNotFoundError",
    "technology": {
      "framework": "nextjs",
      "library": "shadcn-ui"
    }
  },
  "context": {
    "files": ["src/components/Dashboard.tsx"]
  },
  "matchingMode": "comprehensive"  // "fast" | "comprehensive"
}
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "matches": [
      {
        "patternId": "shadcn-missing-component",
        "confidence": 0.97,
        "matchType": "exact",
        "matchingFactors": [
          {
            "factor": "error_message",
            "score": 0.95,
            "details": "High similarity in error message pattern"
          },
          {
            "factor": "technology_stack",
            "score": 1.0,
            "details": "Exact match for Shadcn UI + Next.js"
          }
        ],
        "recommendedResolution": {
          "strategy": "dependency_installation",
          "confidence": 0.95,
          "estimatedTime": 120
        }
      }
    ],
    "newPattern": false,
    "processingTime": 0.15
  }
}
```

---

## 📊 **Analytics API**

### **Global Analytics Overview**
**Endpoint:** `GET /analytics/overview`  
**Purpose:** Get global error analytics and trends  
**Rate Limit:** 200 requests/minute  

#### **Query Parameters**
```
?time_range=string         # Time range (1d, 7d, 30d, 90d, 1y)
&projects=string[]         # Filter by specific projects
&categories=string[]       # Filter by error categories
&include_predictions=bool  # Include predictive analytics
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "summary": {
      "totalErrors": 1547,
      "resolvedErrors": 1421,
      "resolutionRate": 0.919,
      "averageResolutionTime": 142.5,
      "uniquePatterns": 89,
      "projectsActive": 12
    },
    "trends": {
      "errorVolume": {
        "current": 156,
        "previous": 178,
        "change": -0.124,
        "trend": "decreasing"
      },
      "resolutionTime": {
        "current": 142.5,
        "previous": 165.8,
        "change": -0.141,
        "trend": "improving"
      }
    },
    "topCategories": [
      {
        "category": "dependency_missing",
        "count": 234,
        "percentage": 15.1,
        "resolutionRate": 0.95
      },
      {
        "category": "build_failures",
        "count": 189,
        "percentage": 12.2,
        "resolutionRate": 0.87
      }
    ],
    "topPatterns": [
      {
        "patternId": "shadcn-missing-component",
        "name": "Shadcn UI Component Missing",
        "occurrences": 23,
        "successRate": 0.95
      }
    ],
    "projectMetrics": [
      {
        "projectName": "ai-dashboard-v2",
        "errorCount": 67,
        "resolutionRate": 0.94,
        "averageResolutionTime": 98.5
      }
    ]
  }
}
```

### **Project-Specific Analytics**
**Endpoint:** `GET /analytics/projects/{project_id}`  
**Purpose:** Get detailed analytics for a specific project  

#### **Response**
```json
{
  "success": true,
  "data": {
    "project": {
      "id": "proj_ai_dashboard_v2",
      "name": "ai-dashboard-v2",
      "repository": "github.com/company/ai-dashboard-v2"
    },
    "summary": {
      "totalErrors": 67,
      "resolvedErrors": 63,
      "resolutionRate": 0.94,
      "averageResolutionTime": 98.5,
      "errorFrequency": 2.1
    },
    "breakdown": {
      "byCategory": [
        {
          "category": "dependency_missing",
          "count": 15,
          "percentage": 22.4
        }
      ],
      "bySeverity": [
        {
          "severity": "medium",
          "count": 34,
          "percentage": 50.7
        }
      ],
      "byAgent": [
        {
          "agentType": "frontend-development",
          "count": 42,
          "percentage": 62.7
        }
      ]
    },
    "trends": {
      "dailyErrorCounts": [
        {
          "date": "2025-08-19",
          "count": 3
        },
        {
          "date": "2025-08-18",
          "count": 5
        }
      ]
    },
    "recommendations": {
      "immediateActions": [
        "Add pre-commit hooks for dependency validation",
        "Implement component scanner for Shadcn UI"
      ],
      "preventionOpportunities": [
        "87% of errors could be prevented with proper tooling"
      ]
    }
  }
}
```

### **Error Trends Analysis**
**Endpoint:** `GET /analytics/trends`  
**Purpose:** Get detailed trend analysis and predictions  

#### **Query Parameters**
```
?metric=string            # Metric to analyze (volume, resolution_time, patterns)
&time_range=string        # Analysis time range
&granularity=string       # Data granularity (hour, day, week, month)
&include_forecast=bool    # Include future predictions
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "metric": "error_volume",
    "timeRange": "30d",
    "granularity": "day",
    "dataPoints": [
      {
        "timestamp": "2025-08-19T00:00:00.000Z",
        "value": 23,
        "trend": "stable"
      }
    ],
    "statistics": {
      "mean": 18.7,
      "median": 17.0,
      "standardDeviation": 6.2,
      "min": 8,
      "max": 34
    },
    "forecast": {
      "enabled": true,
      "horizon": "7d",
      "confidence": 0.85,
      "predictions": [
        {
          "timestamp": "2025-08-20T00:00:00.000Z",
          "predicted": 19.2,
          "confidenceInterval": {
            "lower": 15.1,
            "upper": 23.3
          }
        }
      ]
    },
    "insights": [
      "Error volume has decreased by 15% over the last 7 days",
      "Weekend error rates are 40% lower than weekdays",
      "Peak error times: 10:00-12:00 and 14:00-16:00 UTC"
    ]
  }
}
```

---

## 🔧 **Configuration API**

### **Get System Configuration**
**Endpoint:** `GET /config`  
**Purpose:** Get current system configuration  
**Authentication:** Admin level required  

#### **Response**
```json
{
  "success": true,
  "data": {
    "version": "1.0.0",
    "features": {
      "patternMatching": {
        "enabled": true,
        "mlEnhanced": true,
        "confidenceThreshold": 0.6
      },
      "autoResolution": {
        "enabled": true,
        "maxAttempts": 3,
        "timeoutSeconds": 300
      },
      "analytics": {
        "realTime": true,
        "retention": "2y",
        "aggregation": "daily"
      }
    },
    "limits": {
      "errorSubmission": {
        "rateLimit": "100/minute",
        "maxSize": "1MB"
      },
      "patternQuery": {
        "rateLimit": "500/minute",
        "maxResults": 100
      }
    },
    "integrations": {
      "git": {
        "enabled": true,
        "autoCommit": true,
        "branchStrategy": "main"
      },
      "notifications": {
        "slack": true,
        "email": true,
        "webhook": true
      }
    }
  }
}
```

### **Update Configuration**
**Endpoint:** `PUT /config`  
**Purpose:** Update system configuration  
**Authentication:** Admin level required  

#### **Request Body**
```json
{
  "features": {
    "autoResolution": {
      "maxAttempts": 5,
      "timeoutSeconds": 600
    }
  },
  "limits": {
    "errorSubmission": {
      "rateLimit": "200/minute"
    }
  }
}
```

---

## 🔐 **Authentication & Authorization API**

### **Get API Token**
**Endpoint:** `POST /auth/token`  
**Purpose:** Obtain JWT token for API access  

#### **Request Body**
```json
{
  "apiKey": "gekb_api_key_abc123",
  "projectId": "proj_ai_dashboard_v2",
  "scopes": ["errors:write", "patterns:read", "analytics:read"]
}
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 3600,
    "tokenType": "Bearer",
    "scopes": ["errors:write", "patterns:read", "analytics:read"],
    "projectId": "proj_ai_dashboard_v2"
  }
}
```

### **Refresh Token**
**Endpoint:** `POST /auth/refresh`  
**Purpose:** Refresh expired JWT token  

#### **Request Body**
```json
{
  "refreshToken": "refresh_token_xyz789"
}
```

---

## 🚀 **Webhook API**

### **Register Webhook**
**Endpoint:** `POST /webhooks`  
**Purpose:** Register webhook for real-time notifications  

#### **Request Body**
```json
{
  "url": "https://your-app.com/webhooks/gekb",
  "events": [
    "error.processed",
    "pattern.discovered",
    "resolution.completed"
  ],
  "secret": "webhook_secret_key",
  "active": true,
  "filters": {
    "projects": ["proj_ai_dashboard_v2"],
    "categories": ["dependency_missing", "build_failures"]
  }
}
```

#### **Webhook Payload Example**
```json
{
  "event": "error.processed",
  "timestamp": "2025-08-19T14:32:15.000Z",
  "data": {
    "errorId": "gekb-2025-0819-1432-1247",
    "projectId": "proj_ai_dashboard_v2",
    "category": "dependency_missing",
    "resolved": true,
    "resolutionTime": 142.5,
    "patternMatched": "shadcn-missing-component"
  },
  "signature": "sha256=abc123..."
}
```

---

## 📚 **SDK Examples**

### **Python SDK Usage**
```python
from gekb_sdk import GEKBClient

# Initialize client
client = GEKBClient(
    api_key="gekb_api_key_abc123",
    project_id="proj_ai_dashboard_v2",
    base_url="https://api.gekb.company.com/v1"
)

# Submit error
error_data = {
    "error": {
        "message": "Cannot resolve module '@/components/ui/button'",
        "type": "ModuleNotFoundError",
        "category": "dependency_missing"
    },
    "context": {
        "userAction": "component_import",
        "featureBeingWorked": "dashboard_layout"
    }
}

result = await client.submit_error(error_data)
print(f"Error submitted: {result.error_id}")

# Search patterns
patterns = await client.search_patterns(
    category="dependency_missing",
    technology="shadcn-ui"
)

# Get analytics
analytics = await client.get_project_analytics(
    time_range="30d",
    include_predictions=True
)
```

### **Node.js SDK Usage**
```javascript
import { GEKBClient } from '@gekb/sdk';

// Initialize client
const client = new GEKBClient({
  apiKey: 'gekb_api_key_abc123',
  projectId: 'proj_ai_dashboard_v2',
  baseURL: 'https://api.gekb.company.com/v1'
});

// Submit error
const errorData = {
  error: {
    message: "Cannot resolve module '@/components/ui/button'",
    type: 'ModuleNotFoundError',
    category: 'dependency_missing'
  },
  context: {
    userAction: 'component_import',
    featureBeingWorked: 'dashboard_layout'
  }
};

const result = await client.submitError(errorData);
console.log(`Error submitted: ${result.errorId}`);

// Pattern matching
const matches = await client.matchPatterns({
  error: errorData.error,
  context: errorData.context
});

console.log(`Found ${matches.length} pattern matches`);
```

---

## 🔍 **Error Codes Reference**

### **API Error Codes**
```json
{
  "INVALID_REQUEST": {
    "code": 400,
    "message": "Request validation failed",
    "details": "Check request body format and required fields"
  },
  "UNAUTHORIZED": {
    "code": 401,
    "message": "Authentication required",
    "details": "Provide valid API key or JWT token"
  },
  "FORBIDDEN": {
    "code": 403,
    "message": "Insufficient permissions",
    "details": "Your API key doesn't have required scopes"
  },
  "NOT_FOUND": {
    "code": 404,
    "message": "Resource not found",
    "details": "The requested resource doesn't exist"
  },
  "RATE_LIMITED": {
    "code": 429,
    "message": "Rate limit exceeded",
    "details": "Wait before making another request"
  },
  "PROCESSING_ERROR": {
    "code": 500,
    "message": "Error processing failed",
    "details": "Internal error during error processing"
  },
  "SERVICE_UNAVAILABLE": {
    "code": 503,
    "message": "Service temporarily unavailable",
    "details": "System is under maintenance or overloaded"
  }
}
```

This comprehensive API documentation provides all the specifications needed to integrate with the Global Error Knowledge Base system, including detailed request/response examples, authentication methods, and SDK usage patterns.