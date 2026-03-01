# Services Layer

Business logic is encapsulated here, decoupled from Next.js route handlers.
Each service file exports pure functions or classes that can be unit-tested
without starting the web server.

## Services

| File                    | Responsibility                                  |
| ----------------------- | ----------------------------------------------- |
| `session.service.ts`    | Orchestrator session CRUD and status management |
| `evaluation.service.ts` | CTO evaluation run lifecycle and result parsing |
| `agent.service.ts`      | Agent registry loading and suggestion logic     |

## Usage Pattern

```typescript
// In an API route handler:
import { getSessionById } from '@/services/session.service';

export async function GET(req, { params }) {
  const session = await getSessionById(params.id);
  return NextResponse.json(session);
}
```

Route handlers should be thin — validation, auth, and HTTP concerns only.
All business logic lives in `src/services/`.
