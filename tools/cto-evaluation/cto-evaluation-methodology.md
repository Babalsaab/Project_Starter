# CTO Codebase Evaluation Methodology

> **Comprehensive Guide to Evaluating All 495 Parameters**
> **Purpose:** Educational deep-dive into evaluation techniques, tools, and scoring criteria
> **Companion to:** `cto-codebase-evaluation-framework.md`

---

## Table of Contents

1. [Evaluation Philosophy](#evaluation-philosophy)
2. [Tool Stack Overview](#tool-stack-overview)
3. [Code Quality Evaluation (Parameters 1-32)](#1-code-quality-evaluation-parameters-1-32)
4. [Architecture Evaluation (Parameters 33-58)](#2-architecture-evaluation-parameters-33-58)
5. [Security Evaluation (Parameters 59-96)](#3-security-evaluation-parameters-59-96)
6. [Performance Evaluation (Parameters 97-130)](#4-performance-evaluation-parameters-97-130)
7. [Testing Evaluation (Parameters 131-152)](#5-testing-evaluation-parameters-131-152)
8. [DevOps Evaluation (Parameters 153-176)](#6-devops-evaluation-parameters-153-176)
9. [Scalability Evaluation (Parameters 177-194)](#7-scalability-evaluation-parameters-177-194)
10. [Reliability Evaluation (Parameters 195-216)](#8-reliability-evaluation-parameters-195-216)
11. [Data Architecture Evaluation (Parameters 217-236)](#9-data-architecture-evaluation-parameters-217-236)
12. [API Evaluation (Parameters 237-258)](#10-api-evaluation-parameters-237-258)
13. [Frontend Evaluation (Parameters 259-282)](#11-frontend-evaluation-parameters-259-282)
14. [Backend Evaluation (Parameters 283-302)](#12-backend-evaluation-parameters-283-302)
15. [Mobile Evaluation (Parameters 303-320)](#13-mobile-evaluation-parameters-303-320)
16. [Documentation Evaluation (Parameters 321-330)](#14-documentation-evaluation-parameters-321-330)
17. [Developer Experience Evaluation (Parameters 331-340)](#15-developer-experience-evaluation-parameters-331-340)
18. [Maintainability Evaluation (Parameters 341-352)](#16-maintainability-evaluation-parameters-341-352)
19. [Compliance Evaluation (Parameters 353-364)](#17-compliance-evaluation-parameters-353-364)
20. [Observability Evaluation (Parameters 365-388)](#18-observability-evaluation-parameters-365-388)
21. [Cost Efficiency Evaluation (Parameters 389-398)](#19-cost-efficiency-evaluation-parameters-389-398)
22. [Innovation Evaluation (Parameters 422-433)](#20-innovation-evaluation-parameters-422-433)
23. [UI/UX Consistency Evaluation (Parameters 434-460)](#21-uiux-consistency-evaluation-parameters-434-460)

---

## Evaluation Philosophy

### Three-Tier Evaluation Model

```
┌─────────────────────────────────────────────────────────────┐
│                    EVALUATION TIERS                          │
├─────────────────────────────────────────────────────────────┤
│  TIER 1: AUTOMATED (~60% of parameters)                     │
│  ├── Static Analysis Tools                                  │
│  ├── Linters & Formatters                                   │
│  ├── Security Scanners                                      │
│  └── Metric Collectors                                      │
├─────────────────────────────────────────────────────────────┤
│  TIER 2: SEMI-AUTOMATED (~25% of parameters)                │
│  ├── Scripts + Human Interpretation                         │
│  ├── Pattern Detection with Manual Validation               │
│  └── Aggregated Metrics Requiring Context                   │
├─────────────────────────────────────────────────────────────┤
│  TIER 3: MANUAL REVIEW (~15% of parameters)                 │
│  ├── Architecture Assessment                                │
│  ├── Design Pattern Validation                              │
│  ├── Business Logic Review                                  │
│  └── Security Penetration Testing                           │
└─────────────────────────────────────────────────────────────┘
```

### Scoring Formula

```
Parameter Score = Base Score × Severity Multiplier × Context Factor

Where:
- Base Score: 1-10 from tool output or manual assessment
- Severity Multiplier: 1.0 (normal), 1.2 (high priority), 1.5 (critical)
- Context Factor: 0.8-1.2 based on codebase type/industry
```

### Weighted Category Score

```
Category Score = Σ(Parameter Score × Parameter Weight) / Σ(Parameter Weights)

Final Score = Σ(Category Score × Category Weight)
```

---

## Tool Stack Overview

### Essential Tools by Language

| Language                  | Static Analysis          | Linting          | Security           | Testing      |
| ------------------------- | ------------------------ | ---------------- | ------------------ | ------------ |
| **JavaScript/TypeScript** | SonarQube, ESLint        | Prettier, ESLint | Snyk, Semgrep      | Jest, Vitest |
| **Python**                | SonarQube, Pylint        | Black, Flake8    | Bandit, Safety     | Pytest       |
| **Java**                  | SonarQube, SpotBugs      | Checkstyle       | OWASP DC, SpotBugs | JUnit        |
| **Go**                    | SonarQube, golangci-lint | gofmt            | gosec              | go test      |
| **Rust**                  | SonarQube, Clippy        | rustfmt          | cargo-audit        | cargo test   |
| **Ruby**                  | SonarQube, RuboCop       | RuboCop          | Brakeman           | RSpec        |
| **PHP**                   | SonarQube, PHPStan       | PHP-CS-Fixer     | Psalm              | PHPUnit      |
| **C#**                    | SonarQube, Roslyn        | StyleCop         | Security Code Scan | xUnit        |

### Universal Tools

| Category                | Tools                                    |
| ----------------------- | ---------------------------------------- |
| **Dependency Analysis** | Snyk, Dependabot, OWASP Dependency-Check |
| **Container Security**  | Trivy, Grype, Clair, Anchore             |
| **Infrastructure**      | Checkov, tfsec, cfn-lint, KICS           |
| **API Testing**         | Postman, Insomnia, Dredd, Spectral       |
| **Performance**         | k6, JMeter, Gatling, Lighthouse          |
| **Secrets Detection**   | TruffleHog, GitLeaks, detect-secrets     |

---

## 1. Code Quality Evaluation (Parameters 1-32)

### 1.1 Readability & Clarity (Parameters 1-12)

#### Parameter 1: Naming Conventions

**What We Measure:**

- Consistency of naming patterns across the codebase
- Adherence to language-specific conventions
- Descriptiveness and clarity of names

**Automated Detection:**

```bash
# JavaScript/TypeScript: ESLint naming convention rules
npx eslint --rule '{"@typescript-eslint/naming-convention": "error"}' ./src

# Python: pylint naming checks
pylint --disable=all --enable=C0103,C0104 ./src

# Custom AST analysis script (conceptual)
node analyze-names.js ./src --output=json
```

**Scoring Criteria:**

| Score | Criteria                                             |
| ----- | ---------------------------------------------------- |
| 10    | 100% convention compliance, highly descriptive names |
| 8-9   | >95% compliance, minor inconsistencies               |
| 6-7   | >85% compliance, some unclear names                  |
| 4-5   | >70% compliance, frequent violations                 |
| 1-3   | <70% compliance, inconsistent patterns               |

**Pattern Detection Rules:**

```javascript
// Good patterns to detect
const GOOD_PATTERNS = {
  camelCase: /^[a-z][a-zA-Z0-9]*$/, // variables, functions
  PascalCase: /^[A-Z][a-zA-Z0-9]*$/, // classes, components
  SCREAMING_SNAKE: /^[A-Z][A-Z0-9_]*$/, // constants
  snake_case: /^[a-z][a-z0-9_]*$/, // Python variables
};

// Anti-patterns to flag
const ANTI_PATTERNS = {
  singleChar: /^[a-zA-Z]$/, // x, y, i (except loops)
  abbreviated: /^[a-z]{1,3}$/, // usr, msg, btn
  hungarian: /^(str|int|bool|arr|obj)[A-Z]/, // strName, intCount
  numbered: /[0-9]$/, // handler1, handler2
};
```

---

#### Parameter 2: Code Self-Documentation

**What We Measure:**

- Can code be understood without comments?
- Are function/method names descriptive of behavior?
- Do variable names explain their purpose?

**Evaluation Method:**

```bash
# Calculate comment-to-code ratio
cloc --by-file --json ./src | jq '.SUM.comment / .SUM.code'

# Ideal ratio: 0.1 - 0.3 (10-30% comments)
# Too high (>0.5): Code may not be self-documenting
# Too low (<0.05): May lack necessary documentation
```

**Manual Review Checklist:**

- [ ] Functions named with verbs describing actions (`getUserById`, not `user`)
- [ ] Boolean variables/functions use is/has/should prefixes
- [ ] Collections named with plurals
- [ ] No magic numbers or strings
- [ ] Complex logic has explanatory variable names

**Scoring Matrix:**

| Aspect            | Weight | Assessment            |
| ----------------- | ------ | --------------------- |
| Function naming   | 30%    | Descriptive verbs?    |
| Variable naming   | 30%    | Clear purpose?        |
| Code structure    | 25%    | Logical organization? |
| Comment necessity | 15%    | Only where needed?    |

---

#### Parameter 3: Consistent Formatting

**What We Measure:**

- Uniform indentation (tabs vs spaces)
- Consistent bracket placement
- Line length compliance
- Spacing around operators

**Automated Detection:**

```bash
# JavaScript/TypeScript: Prettier check
npx prettier --check "./src/**/*.{js,ts,tsx}"

# Python: Black check
black --check ./src

# Go: gofmt check
gofmt -d ./src

# Multi-language: EditorConfig check
editorconfig-checker
```

**Configuration Standards:**

```json
// .prettierrc - Industry standard
{
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
```

**Scoring:**

| Score | Criteria                   |
| ----- | -------------------------- |
| 10    | Zero formatting violations |
| 8-9   | <1% files with violations  |
| 6-7   | <5% files with violations  |
| 4-5   | <15% files with violations |
| 1-3   | >15% files with violations |

---

#### Parameter 4: Function Length

**What We Measure:**

- Lines of code per function
- Single responsibility adherence
- Cognitive load per function

**Automated Detection:**

```bash
# JavaScript: ESLint max-lines-per-function
npx eslint --rule '{"max-lines-per-function": ["error", {"max": 50}]}' ./src

# Python: Pylint function length
pylint --max-statements=50 ./src

# Universal: SonarQube method complexity
# Configure in sonar-project.properties:
# sonar.issue.ignore.multicriteria.e1.ruleKey=javascript:S138
```

**Thresholds:**

| Metric             | Excellent | Good | Acceptable | Poor |
| ------------------ | --------- | ---- | ---------- | ---- |
| Lines per function | <20       | <35  | <50        | >50  |
| Statements         | <15       | <25  | <40        | >40  |
| Parameters         | <3        | <5   | <7         | >7   |

**Scoring Formula:**

```python
def score_function_length(avg_lines, max_lines):
    if avg_lines <= 20 and max_lines <= 50:
        return 10
    elif avg_lines <= 35 and max_lines <= 75:
        return 8
    elif avg_lines <= 50 and max_lines <= 100:
        return 6
    elif avg_lines <= 75:
        return 4
    else:
        return 2
```

---

#### Parameter 5: File Organization

**What We Measure:**

- Logical grouping within files
- Import organization
- Section separation
- Related code proximity

**Evaluation Checklist:**

```markdown
## File Organization Checklist

### Header Section (Score: /2)

- [ ] File-level documentation/copyright
- [ ] Clear imports section

### Import Organization (Score: /3)

- [ ] Third-party imports first
- [ ] Internal imports second
- [ ] Alphabetically sorted within groups
- [ ] No unused imports

### Code Structure (Score: /3)

- [ ] Constants/configs at top
- [ ] Types/interfaces defined before use
- [ ] Private helpers before public API
- [ ] Exports at bottom (if applicable)

### File Cohesion (Score: /2)

- [ ] Single responsibility per file
- [ ] Related functions grouped together
```

---

#### Parameter 6: Import/Dependency Organization

**What We Measure:**

- Import ordering and grouping
- Circular dependency absence
- Unused import elimination
- Barrel file usage

**Automated Detection:**

```bash
# JavaScript: Check for circular dependencies
npx madge --circular ./src

# JavaScript: Check for unused imports
npx eslint --rule '{"no-unused-vars": "error", "import/no-unused-modules": "error"}' ./src

# Python: Check imports
isort --check-only ./src
pylint --disable=all --enable=W0611 ./src  # unused imports
```

**Circular Dependency Score:**

| Count | Score |
| ----- | ----- |
| 0     | 10    |
| 1-2   | 7     |
| 3-5   | 5     |
| 6-10  | 3     |
| >10   | 1     |

---

#### Parameter 7: Magic Number Elimination

**What We Measure:**

- Named constants for all literals
- Configuration externalization
- No unexplained values in logic

**Automated Detection:**

```bash
# ESLint magic numbers rule
npx eslint --rule '{"no-magic-numbers": ["error", {"ignore": [0, 1, -1]}]}' ./src

# Custom pattern search
grep -rn "[^a-zA-Z][0-9]\{2,\}[^a-zA-Z0-9]" ./src --include="*.js" --include="*.ts"
```

**Acceptable Magic Numbers:**

- `0, 1, -1` - Array/loop operations
- `100` - Percentage calculations
- `1000` - Milliseconds conversion
- Everything else should be named

**Scoring:**

```python
def score_magic_numbers(violations_per_kloc):
    if violations_per_kloc == 0:
        return 10
    elif violations_per_kloc < 1:
        return 8
    elif violations_per_kloc < 3:
        return 6
    elif violations_per_kloc < 5:
        return 4
    else:
        return 2
```

---

#### Parameter 8: Boolean Clarity

**What We Measure:**

- Boolean variable naming (is/has/should/can prefixes)
- No double negatives
- Clear conditional expressions

**Pattern Detection:**

```javascript
// Good boolean patterns
const GOOD_BOOLEAN = /^(is|has|should|can|will|did|was|are)[A-Z]/;

// Anti-patterns
const BAD_PATTERNS = [
  /!.*!/, // Double negation: if (!notReady)
  /!=.*false/, // if (isReady != false)
  /==.*true/, // if (isReady == true)
];
```

**Manual Review:**

```javascript
// BAD
if (!isNotReady) {
}
if (isReady == true) {
}
const ready = user && user.status;

// GOOD
if (isReady) {
}
if (isReady) {
}
const isUserActive = user?.status === 'active';
```

---

#### Parameters 9-12: Control Flow, Error Messages, Code Density, Language Idioms

**Parameter 9: Control Flow Clarity**

```bash
# Check nesting depth
npx eslint --rule '{"max-depth": ["error", 4]}' ./src

# Check for early returns (prefer guard clauses)
# Manual review for pattern:
# if (condition) { ...long code... } else { return; }
# Should be: if (!condition) { return; } ...code...
```

**Parameter 10: Error Message Quality**

```bash
# Search for generic error messages
grep -rn "throw new Error\s*(\s*['\"]" ./src | grep -E "(error|failed|invalid|wrong)"

# Good: "User authentication failed: invalid token format"
# Bad: "Error occurred"
```

**Parameter 11: Code Density**

```python
# Ideal: 1-2 operations per line
# Calculate average operations per line using AST

def calculate_density(ast):
    operations = count_operations(ast)
    lines = count_lines(ast)
    density = operations / lines
    # Target: 1.0-2.0 operations per line
    return density
```

**Parameter 12: Language Idioms**

| Language   | Idiomatic Pattern              | Anti-Pattern                                    |
| ---------- | ------------------------------ | ----------------------------------------------- |
| JavaScript | `array.map(x => x.id)`         | `for (let i=0; i<arr.length; i++)`              |
| Python     | `[x.id for x in items]`        | `map(lambda x: x.id, items)`                    |
| Go         | `if err != nil { return err }` | Ignoring errors                                 |
| Rust       | `value.unwrap_or_default()`    | `match value { Some(v) => v, None => default }` |

---

### 1.2 Design Principles (Parameters 13-24)

#### Parameter 13: Single Responsibility Principle (SRP)

**What We Measure:**

- Each class/module has one reason to change
- Functions do one thing
- No god classes/modules

**Detection Methods:**

```bash
# Count methods per class (JavaScript)
npx ts-morph-scripts count-methods ./src

# Detect large classes
find ./src -name "*.ts" -exec wc -l {} \; | awk '$1 > 500 {print}'

# SonarQube: Class complexity
# Rule: Classes should not have too many responsibilities
```

**Scoring Heuristics:**

| Metric                 | Excellent | Violation |
| ---------------------- | --------- | --------- |
| Methods per class      | <10       | >20       |
| Lines per class        | <300      | >500      |
| Dependencies per class | <5        | >10       |
| Public methods         | <7        | >15       |

**Manual Review Questions:**

1. Can you describe the class's purpose in one sentence?
2. Does it have multiple unrelated methods?
3. Would changes in unrelated features affect this class?

---

#### Parameter 14: Open/Closed Principle (OCP)

**What We Measure:**

- Extension through inheritance/composition, not modification
- Strategy pattern usage
- Plugin architecture

**Detection Patterns:**

```javascript
// VIOLATION: Adding new types requires modifying existing code
function getPrice(type) {
  switch (type) {
    case 'basic':
      return 10;
    case 'premium':
      return 20;
    // Adding new type requires modifying this function
  }
}

// COMPLIANT: New types are added without modification
const pricingStrategies = {
  basic: () => 10,
  premium: () => 20,
};
const getPrice = (type) => pricingStrategies[type]();
```

**Automated Detection:**

```bash
# Find switch statements with many cases
grep -rn "switch\s*(" ./src | xargs -I {} sh -c 'grep -A 20 "{}" | grep -c "case "'

# Large switch statements (>5 cases) may indicate OCP violation
```

---

#### Parameter 15: Liskov Substitution Principle (LSP)

**What We Measure:**

- Subtypes are substitutable for base types
- No overridden methods that change behavior unexpectedly
- Interface contracts are honored

**Manual Review Checklist:**

- [ ] Derived classes don't throw unexpected exceptions
- [ ] Preconditions are not strengthened in subtypes
- [ ] Postconditions are not weakened in subtypes
- [ ] No type checking (instanceof) to handle subtypes differently

**Code Smells:**

```javascript
// VIOLATION: Type checking indicates LSP violation
function processShape(shape) {
  if (shape instanceof Square) {
    // Special handling for Square
  } else if (shape instanceof Circle) {
    // Special handling for Circle
  }
}
```

---

#### Parameter 16: Interface Segregation Principle (ISP)

**What We Measure:**

- No fat interfaces
- Clients don't depend on methods they don't use
- Multiple focused interfaces over one general interface

**Detection:**

```typescript
// Count methods per interface
// Flag interfaces with >7 methods

// VIOLATION: Fat interface
interface DataService {
  create(): void;
  read(): void;
  update(): void;
  delete(): void;
  validate(): void;
  transform(): void;
  export(): void;
  import(): void;
  // Too many responsibilities
}

// COMPLIANT: Segregated interfaces
interface Readable {
  read(): void;
}
interface Writable {
  create(): void;
  update(): void;
  delete(): void;
}
interface Exportable {
  export(): void;
  import(): void;
}
```

---

#### Parameter 17: Dependency Inversion Principle (DIP)

**What We Measure:**

- High-level modules depend on abstractions
- Low-level modules implement abstractions
- Dependencies are injected, not created

**Detection Patterns:**

```bash
# Find direct instantiation of dependencies
grep -rn "new [A-Z].*Service\|new [A-Z].*Repository\|new [A-Z].*Client" ./src

# Should use dependency injection instead
```

**Scoring Criteria:**

| Pattern               | Score Impact |
| --------------------- | ------------ |
| Full DI container     | +2           |
| Constructor injection | +1           |
| Direct instantiation  | -1           |
| Static dependencies   | -2           |

---

#### Parameter 18: DRY (Don't Repeat Yourself)

**Automated Detection:**

```bash
# JavaScript: jscpd (copy-paste detector)
npx jscpd ./src --min-lines 5 --min-tokens 50 --format json

# Python: CPD
pmd cpd --minimum-tokens 50 --language python --files ./src

# SonarQube duplications
# sonar.cpd.exclusions=**/*Test*
```

**Scoring Formula:**

```python
def score_duplication(percentage):
    if percentage < 1:
        return 10
    elif percentage < 3:
        return 8
    elif percentage < 5:
        return 6
    elif percentage < 10:
        return 4
    else:
        return 2
```

---

#### Parameters 19-24: KISS, YAGNI, Composition, Law of Demeter, Separation of Concerns, Encapsulation

**Parameter 19: KISS - Manual Review Criteria**

| Question                                                      | Score Impact |
| ------------------------------------------------------------- | ------------ |
| Are simple problems solved simply?                            | ±2           |
| Are design patterns used appropriately (not over-engineered)? | ±2           |
| Is the simplest solution that works implemented?              | ±2           |

**Parameter 20: YAGNI Detection**

```bash
# Find unused exports
npx ts-prune ./src

# Find dead code
npx eslint --rule '{"no-unused-vars": "error"}' ./src

# Find unused files
npx unimported ./src
```

**Parameter 21: Composition Over Inheritance**

```bash
# Count inheritance depth
# Flag classes with depth > 3

# Ratio analysis
inheritance_count=$(grep -rn "extends\|implements" ./src | wc -l)
composition_count=$(grep -rn "private readonly\|@Inject\|constructor.*:" ./src | wc -l)
# Ideal ratio: composition >> inheritance
```

**Parameter 22: Law of Demeter**

```javascript
// VIOLATION: Reaching through objects
user.getAddress().getCity().getName();

// COMPLIANT: Direct interaction
user.getCityName();

// Detection: Count chained method calls > 2
grep -rn "\.[a-zA-Z]*()\..[a-zA-Z]*()\..[a-zA-Z]*()" ./src
```

---

### 1.3 Code Complexity Metrics (Parameters 25-32)

#### Parameter 25: Cyclomatic Complexity

**Definition:** Number of linearly independent paths through code

**Calculation:**

```
CC = E - N + 2P
Where:
E = Number of edges in control flow graph
N = Number of nodes
P = Number of connected components
```

**Automated Measurement:**

```bash
# JavaScript
npx complexity-report ./src --format json

# Python
radon cc ./src -a -s --json

# Go
gocyclo -over 10 ./src

# Java
# Use SonarQube or PMD
```

**Scoring Thresholds:**

| Average CC | Maximum CC | Score |
| ---------- | ---------- | ----- |
| 1-5        | <10        | 10    |
| 5-7        | <15        | 8     |
| 7-10       | <20        | 6     |
| 10-15      | <30        | 4     |
| >15        | >30        | 2     |

---

#### Parameter 26: Cognitive Complexity

**Definition:** Measures the mental effort required to understand code (SonarQube metric)

**Key Factors:**

- Nesting increases cognitive load
- Breaks in linear flow (if, for, while)
- Recursion adds complexity

**Measurement:**

```bash
# SonarQube provides this metric
# Or use eslint-plugin-sonarjs
npx eslint --plugin sonarjs --rule '{"sonarjs/cognitive-complexity": ["error", 15]}' ./src
```

---

#### Parameter 27: Nesting Depth

**Automated Detection:**

```bash
# ESLint max-depth
npx eslint --rule '{"max-depth": ["error", 4]}' ./src

# Custom script to measure
```

**Scoring:**

| Max Nesting | Score |
| ----------- | ----- |
| ≤2          | 10    |
| 3           | 8     |
| 4           | 6     |
| 5           | 4     |
| >5          | 2     |

---

#### Parameter 28: Coupling Metrics

**Afferent Coupling (Ca):** Number of classes that depend on this class
**Efferent Coupling (Ce):** Number of classes this class depends on

**Instability Formula:**

```
I = Ce / (Ca + Ce)
I close to 0 = Stable (many dependents)
I close to 1 = Unstable (many dependencies)
```

**Measurement:**

```bash
# JavaScript dependency analysis
npx dependency-cruiser --output-type json ./src

# Calculate coupling metrics from output
```

---

#### Parameters 29-32: Cohesion, LOC/File, Parameter Count, Return Points

**Parameter 29: Cohesion (LCOM4)**

LCOM4 measures whether methods use common attributes:

- LCOM4 = 1: Perfect cohesion (single connected component)
- LCOM4 > 1: Low cohesion (class should be split)

**Parameter 30: Lines of Code per File**

```bash
# Find large files
find ./src -name "*.ts" -exec wc -l {} \; | sort -rn | head -20

# Threshold: <500 lines per file
```

**Parameter 31: Parameter Count**

```bash
# ESLint max-params
npx eslint --rule '{"max-params": ["error", 5]}' ./src
```

**Parameter 32: Return Points**

```bash
# Count return statements per function
# Prefer single return point or clear early returns (guard clauses)
grep -rn "return " ./src | wc -l
```

---

## 2. Architecture Evaluation (Parameters 33-58)

### 2.1 Architectural Patterns (Parameters 33-45)

#### Parameter 33: Architectural Clarity

**Evaluation Criteria:**

| Aspect           | Score | Criteria                            |
| ---------------- | ----- | ----------------------------------- |
| Documentation    | /3    | Architecture decision records exist |
| Folder Structure | /3    | Structure reflects architecture     |
| Boundaries       | /2    | Clear module boundaries             |
| Consistency      | /2    | Pattern applied consistently        |

**Manual Review Checklist:**

- [ ] README explains high-level architecture
- [ ] Architecture diagrams exist and are current
- [ ] Clear folder structure matching architectural layers
- [ ] Consistent patterns across similar modules

---

#### Parameter 34: Layer Separation

**What We Measure:**

- Presentation layer doesn't access data layer directly
- Business logic is isolated from infrastructure
- Dependencies flow in correct direction

**Automated Detection:**

```bash
# Dependency rules check
npx dependency-cruiser --validate ./src

# Define rules in .dependency-cruiser.js
module.exports = {
  forbidden: [
    {
      name: 'presentation-to-data',
      from: { path: 'presentation/' },
      to: { path: 'data/' }
    },
    {
      name: 'domain-to-infrastructure',
      from: { path: 'domain/' },
      to: { path: 'infrastructure/' }
    }
  ]
};
```

**Scoring:**

| Violations | Score |
| ---------- | ----- |
| 0          | 10    |
| 1-2        | 8     |
| 3-5        | 6     |
| 6-10       | 4     |
| >10        | 2     |

---

#### Parameter 35: Domain-Driven Design

**Evaluation Points:**

| Concept             | What to Look For          | Score Weight |
| ------------------- | ------------------------- | ------------ |
| Bounded Contexts    | Clear domain boundaries   | 20%          |
| Ubiquitous Language | Domain terms in code      | 20%          |
| Aggregates          | Proper aggregate roots    | 20%          |
| Value Objects       | Immutable value types     | 15%          |
| Entities            | Identity-based objects    | 15%          |
| Repositories        | Domain-driven data access | 10%          |

**Manual Review:**

```markdown
## DDD Checklist

### Bounded Contexts

- [ ] Each context has clear boundaries
- [ ] Contexts communicate through defined interfaces
- [ ] No shared mutable state between contexts

### Ubiquitous Language

- [ ] Code uses domain terminology
- [ ] No technical jargon in domain layer
- [ ] Names match business concepts

### Aggregates

- [ ] Aggregate roots control access to children
- [ ] Consistency boundaries are enforced
- [ ] References between aggregates use IDs only
```

---

#### Parameters 36-45: Service Patterns

**Parameter 36: Microservices Design**

| Criteria                                        | Score Weight |
| ----------------------------------------------- | ------------ |
| Service independence (can deploy independently) | 25%          |
| Database per service                            | 20%          |
| API-first communication                         | 20%          |
| Proper service sizing (not too big/small)       | 20%          |
| Circuit breakers implemented                    | 15%          |

**Parameter 37: Monolith Modularity**

```bash
# Check module boundaries in monolith
# Each module should have:
# - Own directory
# - Clear public API
# - Internal implementation hidden

# Measure cross-module dependencies
npx madge --image ./architecture.svg ./src
```

**Parameter 38-45: Event-Driven, CQRS, Saga, API Gateway, Service Mesh, Sidecar, Strangler Fig, BFF**

For each pattern, evaluate:

1. Is the pattern needed for this use case?
2. Is it implemented correctly?
3. Is it implemented consistently?

---

### 2.2 System Design Quality (Parameters 46-58)

#### Parameter 46: Component Boundaries

**Automated Analysis:**

```bash
# Generate dependency graph
npx madge --image dependency-graph.svg ./src

# Check for boundary violations
npx dependency-cruiser --output-type dot ./src | dot -T svg > graph.svg
```

**Scoring Criteria:**

| Aspect                              | Score |
| ----------------------------------- | ----- |
| Clear public API per component      | /3    |
| Internal implementation hidden      | /3    |
| No circular dependencies            | /2    |
| Minimal cross-boundary dependencies | /2    |

---

#### Parameter 47: Interface Contracts

**What to Verify:**

```typescript
// Good: Explicit interface contracts
interface UserService {
  getUser(id: string): Promise<User>;
  createUser(data: CreateUserDto): Promise<User>;
}

// Check: Are interfaces defined at module boundaries?
// Check: Are contracts enforced through types?
```

**Automated Checks:**

```bash
# TypeScript strict mode
# tsconfig.json: "strict": true

# API contract validation
npx openapi-validator ./api/openapi.yaml
```

---

#### Parameters 48-58: Dependencies, Abstraction, Cohesion, Cross-Cutting, Config, Feature Flags, Plugins, Versioning, Multi-Tenancy, i18n, Audit

**Parameter 52: Configuration Management**

```bash
# Check for hardcoded configuration
grep -rn "localhost\|127.0.0.1\|:3000\|:5432" ./src --include="*.ts" --include="*.js"

# Check for environment variable usage
grep -rn "process.env\|os.getenv\|System.getenv" ./src | wc -l
```

**Scoring:**

| Practice                 | Score |
| ------------------------ | ----- |
| All config externalized  | 10    |
| Most config externalized | 7     |
| Some hardcoded values    | 5     |
| Significant hardcoding   | 3     |

---

## 3. Security Evaluation (Parameters 59-96)

### 3.1 Authentication & Authorization (Parameters 59-70)

#### Parameter 59: Authentication Mechanism

**Evaluation Matrix:**

| Mechanism               | Modern      | Secure  | Score Modifier |
| ----------------------- | ----------- | ------- | -------------- |
| OAuth 2.0 + OIDC        | Yes         | Yes     | +2             |
| JWT with refresh tokens | Yes         | Depends | +1             |
| Session-based           | Traditional | Yes     | 0              |
| Basic Auth              | Legacy      | Risk    | -2             |
| Custom implementation   | No          | Risk    | -3             |

**Security Checks:**

```bash
# Check for insecure auth patterns
grep -rn "password.*=\|secret.*=\|apiKey.*=" ./src --include="*.ts"

# Check for proper password hashing
grep -rn "bcrypt\|argon2\|scrypt\|pbkdf2" ./src | wc -l
# Should be > 0 if handling passwords
```

---

#### Parameter 60: Multi-Factor Authentication

**Checklist:**

- [ ] MFA supported for all users
- [ ] TOTP implementation (RFC 6238)
- [ ] Recovery codes generated securely
- [ ] MFA bypass protection (no backdoors)

---

#### Parameter 61: Session Management

**Security Audit:**

```bash
# Check session configuration
grep -rn "session\|cookie" ./src --include="*.ts" --include="*.js"

# Verify:
# - HttpOnly flag on session cookies
# - Secure flag (HTTPS only)
# - SameSite attribute
# - Session timeout implemented
# - Session invalidation on logout
```

**Scoring Criteria:**

| Feature             | Required | Score |
| ------------------- | -------- | ----- |
| HttpOnly cookies    | Yes      | /2    |
| Secure flag         | Yes      | /2    |
| SameSite=Strict/Lax | Yes      | /2    |
| Session timeout     | Yes      | /2    |
| Proper invalidation | Yes      | /2    |

---

#### Parameter 62: Token Security (JWT)

**Automated Checks:**

```bash
# Check JWT implementation
grep -rn "jsonwebtoken\|jose\|jwt" ./src

# Verify:
# - Asymmetric signing (RS256) vs symmetric (HS256)
# - Token expiration enforced
# - Refresh token rotation
# - Token revocation capability
```

**JWT Security Checklist:**

| Check                  | Risk if Missing | Score |
| ---------------------- | --------------- | ----- |
| Signature verification | Critical        | /2    |
| Expiration validation  | High            | /2    |
| Algorithm whitelisting | High            | /2    |
| Refresh token rotation | Medium          | /2    |
| Token revocation       | Medium          | /2    |

---

#### Parameter 63: Password Security

**Automated Checks:**

```bash
# Check password hashing
grep -rn "bcrypt\|argon2\|scrypt" ./src

# Check password requirements
grep -rn "password.*length\|minLength\|password.*regex" ./src

# Check for plaintext passwords in logs
grep -rn "console.log.*password\|logger.*password" ./src
```

**Scoring:**

| Practice                    | Score |
| --------------------------- | ----- |
| Argon2id with proper params | 10    |
| bcrypt cost factor ≥12      | 8     |
| bcrypt cost factor <12      | 6     |
| SHA-256 with salt           | 4     |
| MD5/SHA-1/plaintext         | 1     |

---

#### Parameters 64-70: RBAC, ABAC, Privilege Escalation, API Auth, Service Auth, SSO, Federation

**Parameter 64: Role-Based Access Control**

```bash
# Check for authorization middleware
grep -rn "@Authorize\|@Roles\|requireRole\|checkPermission" ./src

# Verify:
# - Roles defined centrally
# - Authorization at API layer
# - Authorization at service layer
# - No hardcoded role checks in business logic
```

---

### 3.2 Data Protection (Parameters 71-82)

#### Parameter 71: Encryption at Rest

**Evaluation:**

| Component    | Encryption Required | Verification Method             |
| ------------ | ------------------- | ------------------------------- |
| Database     | Yes                 | Check DB config, cloud settings |
| File storage | Yes                 | Check S3/blob encryption        |
| Backups      | Yes                 | Check backup encryption         |
| Logs         | If contains PII     | Check log storage               |

---

#### Parameter 72: Encryption in Transit

**Automated Checks:**

```bash
# Check TLS configuration
nmap --script ssl-enum-ciphers -p 443 target.com

# Check for HTTP usage
grep -rn "http://" ./src --include="*.ts" --include="*.js" | grep -v "localhost\|127.0.0.1"

# Check for TLS version requirements
grep -rn "tls\|ssl\|https" ./src
```

**Scoring:**

| Configuration                | Score |
| ---------------------------- | ----- |
| TLS 1.3 only                 | 10    |
| TLS 1.2+ with strong ciphers | 8     |
| TLS 1.2+ with weak ciphers   | 5     |
| TLS 1.1 or below             | 2     |

---

#### Parameters 73-82: Keys, PII, Masking, Secrets, DB Security, Backups, Classification, Retention, Tokenization, Field Encryption

**Parameter 76: Secrets Management**

```bash
# Check for secrets in code
trufflehog git file://. --only-verified

# Check for proper secrets management
grep -rn "Vault\|SecretsManager\|KeyVault\|process.env" ./src

# Verify .gitignore
cat .gitignore | grep -E "\.env|secrets|credentials"
```

---

### 3.3 OWASP Top 10 (Parameters 83-96)

#### Parameter 83: SQL Injection Prevention

**Automated Detection:**

```bash
# Semgrep SQL injection rules
semgrep --config=p/sql-injection ./src

# Check for string concatenation in queries
grep -rn "SELECT.*\+\|INSERT.*\+\|UPDATE.*\+\|DELETE.*\+" ./src

# Check for parameterized queries
grep -rn "\$[0-9]\|?\|:param\|@param" ./src
```

**Scoring:**

| Practice                            | Score |
| ----------------------------------- | ----- |
| ORM with parameterized queries only | 10    |
| Raw SQL with parameterization       | 8     |
| Mix of safe and unsafe patterns     | 5     |
| String concatenation in queries     | 2     |

---

#### Parameter 84: XSS Prevention

**Automated Detection:**

```bash
# Semgrep XSS rules
semgrep --config=p/xss ./src

# Check for dangerous patterns
grep -rn "innerHTML\|dangerouslySetInnerHTML\|v-html\|eval(" ./src

# Check for CSP headers
grep -rn "Content-Security-Policy\|helmet" ./src
```

---

#### Parameter 85: CSRF Protection

**Verification:**

```bash
# Check for CSRF tokens
grep -rn "csrf\|xsrf\|CSRF" ./src

# Check SameSite cookie attribute
grep -rn "sameSite\|SameSite" ./src

# Check for CORS configuration
grep -rn "cors\|CORS\|Access-Control" ./src
```

---

#### Parameters 86-96: Access Control, Misconfiguration, Dependencies, Injection, Deserialization, Logging, SSRF, XXE, Path Traversal, Rate Limiting, Headers

**Parameter 88: Vulnerable Dependencies**

```bash
# JavaScript
npm audit --json
npx snyk test --json

# Python
pip-audit --format json
safety check --json

# All languages
trivy fs --security-checks vuln .
```

**Scoring:**

| Severity                 | Score Impact  |
| ------------------------ | ------------- |
| Critical vulnerabilities | -3 per vuln   |
| High vulnerabilities     | -2 per vuln   |
| Medium vulnerabilities   | -1 per vuln   |
| Low vulnerabilities      | -0.5 per vuln |

**Parameter 96: Security Headers**

```bash
# Check response headers
curl -I https://target.com | grep -E "Strict-Transport|X-Frame-Options|X-Content-Type|Content-Security-Policy"

# Required headers checklist
# - Strict-Transport-Security
# - X-Frame-Options: DENY
# - X-Content-Type-Options: nosniff
# - Content-Security-Policy
# - Referrer-Policy
# - Permissions-Policy
```

---

## 4. Performance Evaluation (Parameters 97-130)

### 4.1 Algorithm & Data Structure Efficiency (Parameters 97-106)

#### Parameter 97: Algorithm Complexity

**Manual Review Focus Areas:**

| Operation Type | Expected Complexity | Red Flags                |
| -------------- | ------------------- | ------------------------ |
| Search         | O(log n) or O(1)    | O(n) in hot paths        |
| Sort           | O(n log n)          | O(n²) for large datasets |
| Lookup         | O(1) hash map       | O(n) array scan          |
| Nested loops   | Avoid in hot paths  | O(n²) or worse           |

**Detection Patterns:**

```javascript
// RED FLAG: O(n²) pattern
items.forEach((item) => {
  const match = otherItems.find((other) => other.id === item.id);
});

// BETTER: O(n) with Map
const otherMap = new Map(otherItems.map((o) => [o.id, o]));
items.forEach((item) => {
  const match = otherMap.get(item.id);
});
```

---

#### Parameter 98: Data Structure Selection

**Review Checklist:**

| Use Case            | Optimal Structure | Anti-Pattern                |
| ------------------- | ----------------- | --------------------------- |
| Key-value lookup    | Map/HashMap       | Array.find                  |
| Unique collection   | Set               | Array with duplicates check |
| Ordered queue       | Priority Queue    | Sorted array                |
| Frequent insertions | LinkedList        | Array.unshift               |

---

### 4.2 Database Performance (Parameters 107-118)

#### Parameter 107: Query Optimization

**Automated Analysis:**

```sql
-- PostgreSQL: Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Find queries without index usage
SELECT schemaname, tablename, seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
  AND seq_tup_read > 10000;
```

**Scoring:**

| Metric         | Target | Score |
| -------------- | ------ | ----- |
| Avg query time | <50ms  | 10    |
| Avg query time | <100ms | 8     |
| Avg query time | <250ms | 6     |
| Avg query time | <500ms | 4     |
| Avg query time | >500ms | 2     |

---

#### Parameter 108: Index Strategy

**Analysis:**

```sql
-- PostgreSQL: Missing index analysis
SELECT
  relname as table,
  seq_scan - idx_scan AS missing_index_impact,
  pg_size_pretty(pg_relation_size(relname::regclass)) AS size
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
ORDER BY missing_index_impact DESC;

-- Index usage statistics
SELECT
  indexrelname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

---

#### Parameter 109: N+1 Query Prevention

**Detection:**

```bash
# Check for N+1 patterns in ORM usage
grep -rn "\.find\|\.findOne\|\.query" ./src | grep -A 5 "forEach\|map\|for"

# Enable query logging and analyze patterns
# Look for repeated identical queries
```

**ORM Configuration Check:**

```javascript
// Good: Eager loading
const users = await User.findAll({
  include: [{ model: Post }, { model: Profile }],
});

// Bad: Lazy loading in loop (N+1)
const users = await User.findAll();
for (const user of users) {
  const posts = await user.getPosts(); // N+1!
}
```

---

### 4.3 Application Performance (Parameters 119-130)

#### Parameter 119: Caching Strategy

**Evaluation Matrix:**

| Cache Layer    | Purpose       | Check For                    |
| -------------- | ------------- | ---------------------------- |
| L1 (In-memory) | Hot data      | LRU cache implementation     |
| L2 (Redis)     | Shared cache  | Redis/Memcached usage        |
| CDN            | Static assets | CloudFront/Cloudflare config |
| Browser        | Client-side   | Cache-Control headers        |

**Code Analysis:**

```bash
# Check for caching implementation
grep -rn "cache\|redis\|memcache\|Cache" ./src

# Check for cache headers
grep -rn "Cache-Control\|ETag\|Last-Modified" ./src
```

---

#### Parameter 120: Cache Invalidation

**Review Points:**

1. What triggers cache invalidation?
2. Is there a TTL strategy?
3. Are there cache stampede protections?
4. Is cache-aside or write-through used?

---

#### Parameters 121-130: Lazy Loading, Async, Parallel, Memory, Pooling, Compression, Serialization, Hot Path, GC, Profiling

**Parameter 122: Async Processing**

```bash
# Check for async patterns
grep -rn "async\|await\|Promise\|then\|callback" ./src

# Check for blocking operations
grep -rn "readFileSync\|execSync" ./src
```

**Parameter 126: Compression**

```bash
# Check for compression middleware
grep -rn "compression\|gzip\|brotli" ./src

# Test compression
curl -H "Accept-Encoding: gzip" -I https://target.com | grep "Content-Encoding"
```

---

## 5. Testing Evaluation (Parameters 131-152)

### 5.1 Test Coverage & Types (Parameters 131-142)

#### Parameter 131: Unit Test Coverage

**Measurement:**

```bash
# JavaScript/TypeScript
npx nyc --reporter=json-summary npm test
# Read coverage-summary.json for metrics

# Python
pytest --cov=src --cov-report=json

# Go
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

**Scoring:**

| Line Coverage | Branch Coverage | Score |
| ------------- | --------------- | ----- |
| >90%          | >85%            | 10    |
| >80%          | >75%            | 8     |
| >70%          | >65%            | 6     |
| >60%          | >55%            | 4     |
| <60%          | <55%            | 2     |

---

#### Parameter 132: Unit Test Quality

**Quality Metrics:**

```bash
# Mutation testing - measures test effectiveness
npx stryker run
# Score: mutation score percentage

# Test assertion density
grep -rn "expect\|assert\|should" ./tests | wc -l
# Divide by number of tests for density
```

**Scoring:**

| Mutation Score | Score |
| -------------- | ----- |
| >80%           | 10    |
| >70%           | 8     |
| >60%           | 6     |
| >50%           | 4     |
| <50%           | 2     |

---

#### Parameters 133-142: Integration, API, E2E, Performance, Security, Mutation, Regression, Smoke, Chaos, Accessibility

**Parameter 136: Performance Testing**

```bash
# k6 load testing
k6 run --vus 50 --duration 5m load-test.js

# Key metrics to capture:
# - Response time percentiles (p50, p95, p99)
# - Throughput (requests/second)
# - Error rate
# - Resource utilization
```

**Parameter 141: Chaos Engineering**

```yaml
# Chaos Mesh experiment example
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure
spec:
  action: pod-failure
  mode: one
  duration: '30s'
  selector:
    namespaces:
      - production
    labelSelectors:
      app: myapp
```

---

### 5.2 Test Infrastructure (Parameters 143-152)

#### Parameter 143: Test Isolation

**Verification:**

```bash
# Run tests in random order
npm test -- --randomize
pytest --random-order

# If tests fail when randomized, they have hidden dependencies
```

**Scoring:**

| Behavior                    | Score |
| --------------------------- | ----- |
| All tests pass in any order | 10    |
| Tests pass in random order  | 8     |
| Some order dependencies     | 5     |
| Strict order required       | 2     |

---

#### Parameter 147: Test Execution Speed

**Measurement:**

```bash
# Measure test suite duration
time npm test

# Identify slow tests
npm test -- --verbose --detectOpenHandles
pytest --durations=20
```

**Scoring:**

| Duration (per 1000 LOC) | Score |
| ----------------------- | ----- |
| <30s                    | 10    |
| <60s                    | 8     |
| <120s                   | 6     |
| <300s                   | 4     |
| >300s                   | 2     |

---

## 6. DevOps Evaluation (Parameters 153-176)

### 6.1 Build & Deployment (Parameters 153-164)

#### Parameter 153: Build Automation

**Evaluation:**

```bash
# Check for CI/CD configuration
ls -la .github/workflows/ .gitlab-ci.yml Jenkinsfile .circleci/

# Analyze pipeline completeness
# Required stages:
# - Build
# - Test
# - Security scan
# - Deploy
```

**Scoring:**

| Automation Level               | Score |
| ------------------------------ | ----- |
| Full CI/CD with approval gates | 10    |
| CI/CD without approval         | 8     |
| CI only (no CD)                | 6     |
| Manual builds                  | 3     |

---

#### Parameter 154: Build Speed

**Measurement:**

```bash
# Measure build duration
time npm run build
time docker build .

# Check for build caching
grep -rn "cache\|--mount=type=cache" Dockerfile
```

**Scoring:**

| Build Time | Score |
| ---------- | ----- |
| <2 min     | 10    |
| <5 min     | 8     |
| <10 min    | 6     |
| <20 min    | 4     |
| >20 min    | 2     |

---

#### Parameter 160: Blue-Green Deployment

**Verification Checklist:**

- [ ] Two identical environments exist
- [ ] Load balancer can switch between them
- [ ] Database migration strategy for both
- [ ] Quick rollback capability (<5 min)

---

### 6.2 Infrastructure & Containers (Parameters 165-176)

#### Parameter 165: Infrastructure as Code

**Analysis:**

```bash
# Check for IaC files
find . -name "*.tf" -o -name "*.yaml" | grep -E "(terraform|cloudformation|pulumi|ansible)"

# Calculate IaC coverage
# (Resources defined in code) / (Total resources) * 100
```

**Scoring:**

| IaC Coverage | Score |
| ------------ | ----- |
| >95%         | 10    |
| >85%         | 8     |
| >70%         | 6     |
| >50%         | 4     |
| <50%         | 2     |

---

#### Parameter 167: Container Security

**Automated Scanning:**

```bash
# Trivy container scan
trivy image myapp:latest --format json

# Docker Scout (if available)
docker scout cves myapp:latest

# Analyze Dockerfile best practices
hadolint Dockerfile
```

**Scoring Criteria:**

| Finding          | Score Impact |
| ---------------- | ------------ |
| Critical CVE     | -3           |
| High CVE         | -2           |
| Running as root  | -2           |
| No health check  | -1           |
| Large image size | -1           |

---

## 7. Scalability Evaluation (Parameters 177-194)

### 7.1 Horizontal Scaling (Parameters 177-186)

#### Parameter 177: Stateless Design

**Verification:**

```bash
# Check for in-memory state
grep -rn "global\|static\|singleton" ./src

# Check for session storage
grep -rn "session\|localStorage\|express-session" ./src

# Should use external state stores (Redis, DB)
```

**Scoring:**

| State Management                | Score |
| ------------------------------- | ----- |
| Fully stateless, external state | 10    |
| Mostly stateless, some state    | 7     |
| Sticky sessions required        | 4     |
| In-memory state                 | 2     |

---

#### Parameter 178: Session Externalization

**Check:**

```bash
# Look for session store configuration
grep -rn "RedisStore\|connect-redis\|redis-session" ./src

# Verify session not stored in-memory
grep -rn "MemoryStore\|express-session" ./src
```

---

### 7.2 Vertical Scaling (Parameters 187-194)

#### Parameter 187: Resource Efficiency

**Measurement:**

```bash
# Profile memory usage
node --expose-gc -e "console.log(process.memoryUsage())"

# Profile CPU usage under load
k6 run --vus 100 --duration 1m load-test.js
# Observe CPU metrics during test
```

---

## 8. Reliability Evaluation (Parameters 195-216)

### 8.1 Error Handling (Parameters 195-206)

#### Parameter 195: Exception Handling

**Code Analysis:**

```bash
# Check for try-catch coverage
grep -rn "try\s*{" ./src | wc -l

# Check for unhandled promise rejections
grep -rn "catch\|\.catch\|async" ./src

# Check for error boundaries (React)
grep -rn "componentDidCatch\|ErrorBoundary" ./src
```

**Scoring:**

| Practice                                  | Score |
| ----------------------------------------- | ----- |
| Comprehensive error handling with logging | 10    |
| Error handling at boundaries              | 8     |
| Partial error handling                    | 5     |
| Minimal error handling                    | 3     |

---

#### Parameter 198: Circuit Breaker

**Detection:**

```bash
# Check for circuit breaker libraries
grep -rn "opossum\|cockatiel\|resilience4j\|hystrix\|polly" ./src

# Check for circuit breaker configuration
grep -rn "circuitBreaker\|CircuitBreaker" ./src
```

---

#### Parameter 200: Timeout Management

**Verification:**

```bash
# Check for timeouts on external calls
grep -rn "timeout\|Timeout\|TIMEOUT" ./src

# Check HTTP client configuration
grep -rn "axios\|fetch\|http\|request" ./src | grep -i timeout
```

**Scoring:**

| Coverage                          | Score |
| --------------------------------- | ----- |
| All external calls have timeouts  | 10    |
| Most external calls have timeouts | 7     |
| Some timeouts configured          | 4     |
| No timeout management             | 1     |

---

### 8.2 High Availability (Parameters 207-216)

#### Parameter 207: Redundancy

**Infrastructure Review:**

| Component           | Redundancy Required     |
| ------------------- | ----------------------- |
| Load balancer       | Yes (multiple AZs)      |
| Application servers | Yes (min 2 instances)   |
| Database            | Yes (primary + replica) |
| Cache               | Yes (cluster mode)      |
| Queue               | Yes (clustered)         |

---

#### Parameter 210: Disaster Recovery

**Evaluation:**

| Metric               | Target    | Verification           |
| -------------------- | --------- | ---------------------- |
| RTO (Recovery Time)  | <4 hours  | Test DR procedure      |
| RPO (Recovery Point) | <1 hour   | Check backup frequency |
| DR testing           | Quarterly | Review test records    |

---

## 9. Data Architecture Evaluation (Parameters 217-236)

### 9.1 Data Modeling (Parameters 217-226)

#### Parameter 217: Schema Design

**Analysis:**

```bash
# Export schema
pg_dump --schema-only database > schema.sql

# Analyze normalization
# Check for:
# - Repeated data groups
# - Dependencies on non-key attributes
# - Multi-valued attributes
```

**Normalization Scoring:**

| Form                       | Score |
| -------------------------- | ----- |
| BCNF/4NF where appropriate | 10    |
| 3NF                        | 8     |
| 2NF                        | 5     |
| 1NF only                   | 3     |

---

#### Parameter 220: Constraints

**Verification:**

```sql
-- PostgreSQL: List constraints
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'tablename'::regclass;

-- Check for:
-- Primary keys on all tables
-- Foreign keys for relationships
-- NOT NULL where appropriate
-- Check constraints for data validation
```

---

### 9.2 Data Operations (Parameters 227-236)

#### Parameter 227: Migration Strategy

**Evaluation:**

```bash
# Check for migration files
ls -la ./migrations/ ./db/migrations/

# Check migration tool
grep -rn "knex\|sequelize\|prisma\|typeorm\|flyway\|liquibase" package.json

# Verify rollback capability
# Each migration should have down() function
```

---

## 10. API Evaluation (Parameters 237-258)

### 10.1 API Quality (Parameters 237-248)

#### Parameter 237: RESTful Design

**REST Maturity Model Scoring:**

| Level | Description               | Score |
| ----- | ------------------------- | ----- |
| 3     | Hypermedia (HATEOAS)      | 10    |
| 2     | HTTP verbs correctly used | 8     |
| 1     | Resources identified      | 6     |
| 0     | RPC over HTTP             | 3     |

**Automated Validation:**

```bash
# OpenAPI spec validation
npx @stoplight/spectral-cli lint openapi.yaml

# Check endpoint naming
grep -rn "router\.\|app\." ./src | grep -E "(get|post|put|delete|patch)"
```

---

#### Parameter 243: Status Codes

**Verification:**

```bash
# Check for proper status code usage
grep -rn "status\|statusCode" ./src

# Required mappings:
# 200 - OK (GET success)
# 201 - Created (POST success)
# 204 - No Content (DELETE success)
# 400 - Bad Request
# 401 - Unauthorized
# 403 - Forbidden
# 404 - Not Found
# 500 - Internal Server Error
```

---

### 10.2 API Security & Operations (Parameters 249-258)

#### Parameter 250: API Rate Limiting

**Detection:**

```bash
# Check for rate limiting middleware
grep -rn "rateLimit\|throttle\|RateLimit" ./src

# Check rate limit headers
curl -I https://api.example.com/endpoint | grep -i "rate\|limit"
```

---

#### Parameter 251: API Documentation

**Evaluation:**

```bash
# Check for OpenAPI/Swagger
ls -la ./openapi.yaml ./swagger.yaml ./api-docs/

# Validate completeness
npx @stoplight/spectral-cli lint openapi.yaml --ruleset=documentation
```

**Scoring:**

| Coverage                                | Score |
| --------------------------------------- | ----- |
| 100% endpoints documented with examples | 10    |
| 100% endpoints documented               | 8     |
| >80% endpoints documented               | 6     |
| >50% endpoints documented               | 4     |
| <50% documented                         | 2     |

---

## 11. Frontend Evaluation (Parameters 259-282)

### 11.1 Architecture & Performance (Parameters 259-270)

#### Parameter 259: Component Architecture

**Analysis:**

```bash
# Count components
find ./src -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" | wc -l

# Check component size
find ./src -name "*.tsx" -exec wc -l {} \; | awk '$1 > 300 {print}'

# Check for barrel exports
ls -la ./src/components/index.ts
```

**Scoring:**

| Metric                | Target | Score |
| --------------------- | ------ | ----- |
| Avg component LOC     | <150   | +2    |
| Max component LOC     | <300   | +2    |
| Reusable components   | >50%   | +3    |
| Single responsibility | Yes    | +3    |

---

#### Parameter 262: Bundle Size

**Measurement:**

```bash
# Build and analyze
npm run build
npx webpack-bundle-analyzer ./dist/stats.json

# Or for Vite
npx vite-bundle-visualizer
```

**Scoring:**

| Initial Bundle | Score |
| -------------- | ----- |
| <100KB gzipped | 10    |
| <250KB gzipped | 8     |
| <500KB gzipped | 6     |
| <1MB gzipped   | 4     |
| >1MB gzipped   | 2     |

---

#### Parameter 271: Core Web Vitals

**Measurement:**

```bash
# Lighthouse CLI
npx lighthouse https://example.com --output=json --chrome-flags="--headless"

# Key metrics:
# LCP (Largest Contentful Paint) - <2.5s
# FID (First Input Delay) - <100ms
# CLS (Cumulative Layout Shift) - <0.1
```

**Scoring:**

| Lighthouse Score | Our Score |
| ---------------- | --------- |
| 90-100           | 10        |
| 80-89            | 8         |
| 70-79            | 6         |
| 50-69            | 4         |
| <50              | 2         |

---

#### Parameter 272: Accessibility (a11y)

**Automated Testing:**

```bash
# axe-core CLI
npx @axe-core/cli https://example.com

# pa11y
npx pa11y https://example.com --reporter json

# Lighthouse accessibility
npx lighthouse https://example.com --only-categories=accessibility
```

**Scoring:**

| WCAG Level   | Violations         | Score |
| ------------ | ------------------ | ----- |
| AA compliant | 0 critical/serious | 10    |
| AA mostly    | <5 moderate        | 7     |
| A compliant  | <10 moderate       | 5     |
| Major issues | Many violations    | 2     |

---

## 12. Backend Evaluation (Parameters 283-302)

### 12.1 Service Implementation (Parameters 283-294)

#### Parameter 286: Dependency Injection

**Detection:**

```bash
# Check for DI framework
grep -rn "inversify\|tsyringe\|typedi\|nestjs" ./src

# Check for manual DI
grep -rn "constructor\|@Inject" ./src
```

**Scoring:**

| Practice                           | Score |
| ---------------------------------- | ----- |
| DI container with proper scoping   | 10    |
| Constructor injection consistently | 8     |
| Mix of patterns                    | 5     |
| Direct instantiation               | 3     |

---

### 12.2 Real-Time (Parameters 295-302)

#### Parameter 295: WebSocket Implementation

**Evaluation:**

```bash
# Check for WebSocket library
grep -rn "ws\|socket.io\|websocket" ./src

# Verify:
# - Connection management
# - Heartbeat/ping-pong
# - Reconnection logic
# - Message queuing for offline
```

---

## 13. Mobile Evaluation (Parameters 303-320)

### 13.1 Mobile Architecture (Parameters 303-312)

#### Parameter 303: Architecture Pattern

**Evaluation:**

| Pattern            | Modern      | Score Modifier |
| ------------------ | ----------- | -------------- |
| Clean Architecture | Yes         | +2             |
| MVVM               | Yes         | +1             |
| MVI                | Yes         | +1             |
| MVP                | Traditional | 0              |
| No clear pattern   | No          | -2             |

---

### 13.2 Mobile Performance (Parameters 313-320)

#### Parameter 313: App Launch Time

**Measurement:**

```bash
# Android
adb shell am start -W com.example.app/.MainActivity | grep "TotalTime"

# iOS (via Instruments)
# Use Time Profiler to measure app launch
```

**Scoring:**

| Cold Start | Score |
| ---------- | ----- |
| <1s        | 10    |
| <2s        | 8     |
| <3s        | 6     |
| <5s        | 4     |
| >5s        | 2     |

---

## 14. Documentation Evaluation (Parameters 321-330)

### 14.1 Code Documentation (Parameters 321-330)

#### Parameter 321: README Quality

**Checklist:**

| Section                   | Required     | Score |
| ------------------------- | ------------ | ----- |
| Project description       | Yes          | /1    |
| Installation instructions | Yes          | /2    |
| Usage examples            | Yes          | /2    |
| API documentation         | Yes          | /2    |
| Contributing guide        | Nice-to-have | /1    |
| License                   | Yes          | /1    |
| Badges (CI, coverage)     | Nice-to-have | /1    |

---

## 15. Developer Experience Evaluation (Parameters 331-340)

### 15.1 Development Environment (Parameters 331-340)

#### Parameter 331: Setup Simplicity

**Test:**

```bash
# Time the setup process
time (git clone repo && cd repo && npm install && npm run dev)

# Target: <5 minutes
```

**Scoring:**

| Setup Time | Commands     | Score |
| ---------- | ------------ | ----- |
| <2 min     | 1-2 commands | 10    |
| <5 min     | 3-4 commands | 8     |
| <15 min    | 5+ commands  | 5     |
| >15 min    | Complex      | 2     |

---

## 16. Maintainability Evaluation (Parameters 341-352)

### 16.1 Code Health (Parameters 341-352)

#### Parameter 341: Technical Debt Ratio

**Measurement:**

```bash
# SonarQube technical debt ratio
# (Remediation cost / Development cost) * 100

# Target: <5%
```

**Scoring:**

| Debt Ratio | Score |
| ---------- | ----- |
| <2%        | 10    |
| <5%        | 8     |
| <10%       | 6     |
| <20%       | 4     |
| >20%       | 2     |

---

#### Parameter 347: Dependency Freshness

**Measurement:**

```bash
# JavaScript: Check outdated
npm outdated --json

# Python
pip list --outdated --format json
```

**Scoring:**

| Outdated % | Score |
| ---------- | ----- |
| <5%        | 10    |
| <15%       | 8     |
| <30%       | 6     |
| <50%       | 4     |
| >50%       | 2     |

---

## 17. Compliance Evaluation (Parameters 353-364)

### 17.1 Regulatory Compliance (Parameters 353-364)

#### Parameter 353: GDPR Compliance

**Checklist:**

| Requirement       | Verification                  |
| ----------------- | ----------------------------- |
| Data inventory    | Document all PII collected    |
| Consent tracking  | Verify opt-in mechanism       |
| Right to access   | API for data export           |
| Right to erasure  | Delete user data endpoint     |
| Data minimization | Only necessary data collected |
| Privacy by design | Built into architecture       |

---

## 18. Observability Evaluation (Parameters 365-388)

### 18.1 Logging & Tracing (Parameters 365-376)

#### Parameter 365: Structured Logging

**Detection:**

```bash
# Check for structured logging
grep -rn "winston\|pino\|bunyan\|log4j\|logrus" ./src

# Check log format
# Should output JSON, not plain text
```

**Example Good Pattern:**

```javascript
// Structured log
logger.info({
  event: 'user_login',
  userId: user.id,
  ip: request.ip,
  timestamp: new Date().toISOString(),
});
```

---

### 18.2 Metrics & Alerting (Parameters 377-388)

#### Parameter 377: Application Metrics

**Detection:**

```bash
# Check for metrics library
grep -rn "prometheus\|prom-client\|statsd\|datadog" ./src

# Verify custom metrics
grep -rn "counter\|gauge\|histogram\|summary" ./src
```

---

## 19. Cost Efficiency Evaluation (Parameters 389-398)

### 19.1 Infrastructure Costs (Parameters 389-398)

#### Parameter 389: Right-Sizing

**Analysis:**

```bash
# AWS - Check instance utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --statistics Average \
  --period 3600 \
  --start-time $(date -d '7 days ago' --iso-8601) \
  --end-time $(date --iso-8601)

# Target: 60-80% utilization
# <40% = Oversized
# >90% = Undersized
```

---

## 20. Innovation Evaluation (Parameters 422-433)

### 20.1 Technology Currency (Parameters 422-433)

---

## 21. UI/UX Consistency Evaluation (Parameters 434-460)

### 21.1 Design System & UX Integrity (Parameters 434-460)

| #   | Parameter                     | Description                       | Score | Notes |
| --- | ----------------------------- | --------------------------------- | ----- | ----- |
| 434 | **Design Tokens**             | Token usage and coverage          |       |       |
| 435 | **Color System**              | Palette consistency and contrast  |       |       |
| 436 | **Typography**                | Scale, rhythm, and hierarchy      |       |       |
| 437 | **Spacing System**            | Grid adherence and spacing tokens |       |       |
| 438 | **Component Library**         | Reuse and composability           |       |       |
| 439 | **Responsive Design**         | Breakpoints and fluid layouts     |       |       |
| 440 | **Motion & Animation**        | Easing, duration, reduced-motion  |       |       |
| 441 | **Accessibility (a11y)**      | Keyboard, focus, contrast         |       |       |
| 442 | **CSS Architecture**          | Specificity, layering, patterns   |       |       |
| 443 | **Dark Mode**                 | Theme parity and coverage         |       |       |
| 444 | **Z-Index System**            | Layering discipline               |       |       |
| 445 | **Visual Hierarchy**          | Information hierarchy consistency |       |       |
| 446 | **Visual Regression**         | Drift detection and baselines     |       |       |
| 447 | **Token Coverage**            | Hardcoded vs tokenized styles     |       |       |
| 448 | **Component API Consistency** | Prop naming and variants          |       |       |
| 449 | **State Coverage**            | Hover, focus, loading, empty      |       |       |
| 450 | **Form UX**                   | Labels, validation, errors        |       |       |
| 451 | **Layout Stability (CLS)**    | Image sizing, font display        |       |       |
| 452 | **Input Modality**            | Touch/keyboard/pointer support    |       |       |
| 453 | **Iconography**               | Icon system consistency           |       |       |
| 454 | **Microcopy**                 | Label clarity and consistency     |       |       |
| 455 | **UI Performance**            | Paint and render patterns         |       |       |
| 456 | **Internationalization**      | RTL and text resilience           |       |       |
| 457 | **UX Safety**                 | Destructive action safeguards     |       |       |
| 458 | **Design-Code Parity**        | Design tooling alignment          |       |       |
| 459 | **Entropy & Governance**      | Pattern sprawl and reuse          |       |       |
| 460 | **Developer Experience (DX)** | Storybook, docs, tooling          |       |       |

#### Parameter 399: Technology Currency

**Evaluation:**

| Component      | Modern | Legacy      | EOL      |
| -------------- | ------ | ----------- | -------- |
| Node.js 20+    | +2     | 16-18: 0    | <16: -2  |
| React 18+      | +2     | 16-17: 0    | <16: -2  |
| Python 3.11+   | +2     | 3.8-3.10: 0 | <3.8: -2 |
| PostgreSQL 15+ | +2     | 12-14: 0    | <12: -2  |

**Automated Check:**

```bash
# Check package versions
npm ls --depth=0 --json | jq '.dependencies | keys[] as $k | "\($k): \(.[$k].version)"'

# Compare against latest versions
npm outdated
```

---

## Appendix: Score Calculation Examples

### Example Calculation

```python
# Category: Security (Weight: 12%)
parameters = {
    'sql_injection': {'score': 9, 'weight': 2},
    'xss_prevention': {'score': 8, 'weight': 2},
    'csrf_protection': {'score': 10, 'weight': 1.5},
    'auth_mechanism': {'score': 7, 'weight': 2},
    # ... more parameters
}

category_score = sum(p['score'] * p['weight'] for p in parameters.values()) / sum(p['weight'] for p in parameters.values())
# category_score = 8.4

weighted_contribution = category_score * 0.12  # 12% weight
# weighted_contribution = 1.008 to final score
```

### Final Score Formula

```
Final Score = Σ(Category Score × Category Weight)

Grade Scale:
A+ = 9.5-10.0
A  = 9.0-9.4
A- = 8.5-8.9
B+ = 8.0-8.4
B  = 7.5-7.9
B- = 7.0-7.4
C+ = 6.5-6.9
C  = 6.0-6.4
C- = 5.5-5.9
D  = 5.0-5.4
F  = <5.0
```

---

## Quick Reference: Tool Commands

```bash
# === CODE QUALITY ===
npx eslint ./src --format json
npx jscpd ./src --format json
radon cc ./src -a -s --json

# === SECURITY ===
npm audit --json
snyk test --json
semgrep --config=auto ./src --json
trufflehog git file://. --json

# === PERFORMANCE ===
npx lighthouse https://example.com --output=json
k6 run load-test.js --out json=results.json

# === TESTING ===
npx nyc --reporter=json-summary npm test
npx stryker run --reporters json

# === DEPENDENCIES ===
npx madge --circular ./src
npm outdated --json
npx dependency-cruiser --output-type json ./src

# === INFRASTRUCTURE ===
trivy image myapp:latest --format json
hadolint Dockerfile --format json
checkov -d . --output json
```

---

_This methodology document provides the technical foundation for systematic codebase evaluation. Each parameter can be assessed using the combination of automated tools and manual review processes described above._
