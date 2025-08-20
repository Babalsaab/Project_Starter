# Global Error Knowledge Base (GEKB) - Deployment Guide

**Document Version:** 1.0  
**Last Updated:** August 19, 2025  
**Document Type:** Production Deployment Guide  
**Dependencies:** GEKB PRD, Task Breakdown, API Documentation  
**Author:** Marcus Chen (DevOps Engineer) + Dr. Elena Vasquez  
**Project:** Global Error Knowledge Base System Deployment  

---

## 🎯 **Deployment Overview**

### **Infrastructure Requirements**
- **Kubernetes Cluster**: v1.27+ with 3+ nodes
- **Database**: PostgreSQL 14+ with high availability
- **Cache**: Redis 7+ cluster setup
- **Storage**: Persistent volumes with backup capabilities
- **Monitoring**: Prometheus + Grafana stack
- **Load Balancer**: NGINX Ingress Controller or AWS ALB

### **Resource Specifications**
```yaml
Production Environment:
  CPU: 16 cores minimum (32 cores recommended)
  Memory: 32GB minimum (64GB recommended)
  Storage: 500GB persistent storage (1TB recommended)
  Network: 10Gbps bandwidth
  
Staging Environment:
  CPU: 8 cores
  Memory: 16GB
  Storage: 200GB persistent storage
  Network: 1Gbps bandwidth
```

### **Security Requirements**
- TLS 1.3 for all communications
- Network policies for pod isolation
- RBAC for service accounts
- Secrets management with encryption at rest
- Regular security scanning and updates

---

## 🏗️ **Phase 1: Infrastructure Setup**

### **Step 1.1: Kubernetes Cluster Preparation**

#### **Create Namespace and RBAC**
```bash
# Create dedicated namespace
kubectl create namespace gekb-system

# Apply RBAC configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gekb-service-account
  namespace: gekb-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gekb-cluster-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "endpoints", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gekb-cluster-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: gekb-cluster-role
subjects:
- kind: ServiceAccount
  name: gekb-service-account
  namespace: gekb-system
EOF
```

#### **Install Required Operators**
```bash
# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus-operator prometheus-community/kube-prometheus-stack \
  --namespace gekb-system \
  --create-namespace \
  --values monitoring-values.yaml

# Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace gekb-system \
  --set controller.metrics.enabled=true \
  --set controller.podAnnotations."prometheus\.io/scrape"=true

# Install Cert-Manager for TLS
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace gekb-system \
  --version v1.12.0 \
  --set installCRDs=true
```

### **Step 1.2: Database Setup (PostgreSQL)**

#### **Create PostgreSQL StatefulSet**
```yaml
# postgresql-ha.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql-ha
  namespace: gekb-system
spec:
  serviceName: postgresql-ha
  replicas: 3
  selector:
    matchLabels:
      app: postgresql-ha
  template:
    metadata:
      labels:
        app: postgresql-ha
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: postgresql
        image: postgres:14-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "gekb_production"
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: password
        - name: POSTGRES_REPLICATION_MODE
          value: "master"
        - name: POSTGRES_REPLICATION_USER
          value: "replicator"
        - name: POSTGRES_REPLICATION_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: replication_password
        volumeMounts:
        - name: postgresql-storage
          mountPath: /var/lib/postgresql/data
        - name: postgresql-config
          mountPath: /etc/postgresql/postgresql.conf
          subPath: postgresql.conf
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "2"
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - exec pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h 127.0.0.1 -p 5432
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - exec pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h 127.0.0.1 -p 5432
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
      volumes:
      - name: postgresql-config
        configMap:
          name: postgresql-config
  volumeClaimTemplates:
  - metadata:
      name: postgresql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "fast-ssd"
      resources:
        requests:
          storage: 100Gi
```

#### **Create Database Secrets**
```bash
# Generate secure passwords
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REPLICATION_PASSWORD=$(openssl rand -base64 32)

# Create Kubernetes secret
kubectl create secret generic postgresql-secret \
  --namespace=gekb-system \
  --from-literal=username=gekb_admin \
  --from-literal=password="$POSTGRES_PASSWORD" \
  --from-literal=replication_password="$REPLICATION_PASSWORD"

# Store passwords securely for later use
echo "PostgreSQL Admin Password: $POSTGRES_PASSWORD" | gpg --encrypt --armor -r admin@company.com > postgres-password.gpg
echo "Replication Password: $REPLICATION_PASSWORD" | gpg --encrypt --armor -r admin@company.com > replication-password.gpg
```

#### **Apply Database Configuration**
```bash
# Create PostgreSQL configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-config
  namespace: gekb-system
data:
  postgresql.conf: |
    # Performance tuning for GEKB workload
    shared_buffers = 1GB
    effective_cache_size = 3GB
    work_mem = 16MB
    maintenance_work_mem = 256MB
    
    # Write-ahead logging
    wal_level = replica
    max_wal_senders = 3
    wal_keep_segments = 64
    
    # Connection settings
    max_connections = 200
    
    # Logging
    log_statement = 'all'
    log_min_duration_statement = 1000
    
    # Checkpoint settings
    checkpoint_completion_target = 0.9
    checkpoint_timeout = 10min
EOF

# Deploy PostgreSQL
kubectl apply -f postgresql-ha.yaml
```

### **Step 1.3: Redis Cluster Setup**

#### **Deploy Redis Cluster**
```yaml
# redis-cluster.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
  namespace: gekb-system
spec:
  serviceName: redis-cluster
  replicas: 6
  selector:
    matchLabels:
      app: redis-cluster
  template:
    metadata:
      labels:
        app: redis-cluster
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        - containerPort: 16379
        command:
        - redis-server
        - /etc/redis/redis.conf
        - --cluster-enabled
        - yes
        - --cluster-config-file
        - /data/nodes.conf
        - --cluster-node-timeout
        - "5000"
        - --appendonly
        - yes
        volumeMounts:
        - name: redis-data
          mountPath: /data
        - name: redis-config
          mountPath: /etc/redis
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: redis-config
        configMap:
          name: redis-config
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "fast-ssd"
      resources:
        requests:
          storage: 20Gi
```

---

## 🚀 **Phase 2: Application Deployment**

### **Step 2.1: Build and Push Docker Images**

#### **Create Multi-Stage Dockerfile**
```dockerfile
# Dockerfile
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.5.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    git \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry==$POETRY_VERSION

# Create app user
RUN groupadd -r gekb && useradd -r -g gekb gekb

# Set work directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Configure poetry and install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction --no-ansi

# Production stage
FROM base as production

# Copy application code
COPY --chown=gekb:gekb . .

# Install additional production dependencies
RUN poetry install --only=main --no-interaction --no-ansi

# Switch to app user
USER gekb

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# Start application
CMD ["python", "-m", "gekb.main"]
```

#### **Build and Push Images**
```bash
# Build application image
docker build -t gekb/api:v1.0.0 .
docker build -t gekb/worker:v1.0.0 -f Dockerfile.worker .
docker build -t gekb/scheduler:v1.0.0 -f Dockerfile.scheduler .

# Tag for registry
docker tag gekb/api:v1.0.0 your-registry.com/gekb/api:v1.0.0
docker tag gekb/worker:v1.0.0 your-registry.com/gekb/worker:v1.0.0
docker tag gekb/scheduler:v1.0.0 your-registry.com/gekb/scheduler:v1.0.0

# Push to registry
docker push your-registry.com/gekb/api:v1.0.0
docker push your-registry.com/gekb/worker:v1.0.0
docker push your-registry.com/gekb/scheduler:v1.0.0
```

### **Step 2.2: Deploy Application Services**

#### **Create ConfigMap for Application Configuration**
```yaml
# gekb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gekb-config
  namespace: gekb-system
data:
  config.yml: |
    database:
      host: postgresql-ha
      port: 5432
      name: gekb_production
      pool_size: 20
      max_overflow: 30
      pool_timeout: 30
      pool_recycle: 3600
    
    redis:
      cluster_nodes:
        - redis-cluster-0.redis-cluster:6379
        - redis-cluster-1.redis-cluster:6379
        - redis-cluster-2.redis-cluster:6379
        - redis-cluster-3.redis-cluster:6379
        - redis-cluster-4.redis-cluster:6379
        - redis-cluster-5.redis-cluster:6379
      password: null
      db: 0
    
    api:
      host: "0.0.0.0"
      port: 8000
      workers: 4
      reload: false
      log_level: "info"
    
    features:
      pattern_matching:
        enabled: true
        ml_enhanced: true
        confidence_threshold: 0.6
      auto_resolution:
        enabled: true
        max_attempts: 3
        timeout_seconds: 300
      analytics:
        real_time: true
        retention: "2y"
        aggregation: "daily"
    
    security:
      jwt_secret_key: "${JWT_SECRET_KEY}"
      jwt_algorithm: "HS256"
      jwt_expiration: 3600
      api_key_length: 32
    
    logging:
      level: "INFO"
      format: "json"
      file_rotation: true
      max_file_size: "100MB"
      backup_count: 10
```

#### **Create Application Secrets**
```bash
# Generate application secrets
JWT_SECRET=$(openssl rand -base64 64)
API_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Create Kubernetes secret
kubectl create secret generic gekb-secrets \
  --namespace=gekb-system \
  --from-literal=jwt_secret_key="$JWT_SECRET" \
  --from-literal=api_encryption_key="$API_ENCRYPTION_KEY" \
  --from-literal=database_url="postgresql://gekb_admin:$POSTGRES_PASSWORD@postgresql-ha:5432/gekb_production"

# Store secrets securely
echo "JWT Secret: $JWT_SECRET" | gpg --encrypt --armor -r admin@company.com > jwt-secret.gpg
echo "API Encryption Key: $API_ENCRYPTION_KEY" | gpg --encrypt --armor -r admin@company.com > api-key.gpg
```

#### **Deploy API Service**
```yaml
# gekb-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gekb-api
  namespace: gekb-system
  labels:
    app: gekb-api
    version: v1.0.0
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: gekb-api
  template:
    metadata:
      labels:
        app: gekb-api
        version: v1.0.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: gekb-api
        image: your-registry.com/gekb/api:v1.0.0
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: GEKB_CONFIG_FILE
          value: "/etc/gekb/config.yml"
        - name: JWT_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: gekb-secrets
              key: jwt_secret_key
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: gekb-secrets
              key: database_url
        volumeMounts:
        - name: config
          mountPath: /etc/gekb
        - name: logs
          mountPath: /app/logs
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 30
      volumes:
      - name: config
        configMap:
          name: gekb-config
      - name: logs
        emptyDir: {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - gekb-api
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: gekb-api-service
  namespace: gekb-system
  labels:
    app: gekb-api
spec:
  selector:
    app: gekb-api
  ports:
  - port: 80
    targetPort: 8000
    name: http
  type: ClusterIP
```

#### **Deploy Worker Service**
```yaml
# gekb-worker-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gekb-worker
  namespace: gekb-system
  labels:
    app: gekb-worker
    version: v1.0.0
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  selector:
    matchLabels:
      app: gekb-worker
  template:
    metadata:
      labels:
        app: gekb-worker
        version: v1.0.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: gekb-worker
        image: your-registry.com/gekb/worker:v1.0.0
        env:
        - name: GEKB_CONFIG_FILE
          value: "/etc/gekb/config.yml"
        - name: WORKER_TYPE
          value: "error_processor"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: gekb-secrets
              key: database_url
        volumeMounts:
        - name: config
          mountPath: /etc/gekb
        - name: logs
          mountPath: /app/logs
        resources:
          requests:
            memory: "2Gi"
            cpu: "1"
          limits:
            memory: "4Gi"
            cpu: "2"
        livenessProbe:
          httpGet:
            path: /health
            port: 9090
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 9090
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      volumes:
      - name: config
        configMap:
          name: gekb-config
      - name: logs
        emptyDir: {}
```

### **Step 2.3: Database Migration and Initial Data**

#### **Run Database Migrations**
```bash
# Create migration job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: gekb-db-migration
  namespace: gekb-system
spec:
  template:
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: migration
        image: your-registry.com/gekb/api:v1.0.0
        command: ["python", "-m", "alembic", "upgrade", "head"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: gekb-secrets
              key: database_url
        volumeMounts:
        - name: config
          mountPath: /etc/gekb
      volumes:
      - name: config
        configMap:
          name: gekb-config
      restartPolicy: Never
  backoffLimit: 3
EOF

# Wait for migration to complete
kubectl wait --for=condition=complete job/gekb-db-migration --namespace=gekb-system --timeout=300s

# Verify migration status
kubectl logs job/gekb-db-migration --namespace=gekb-system
```

#### **Load Initial Data**
```bash
# Create initial data loading job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: gekb-initial-data
  namespace: gekb-system
spec:
  template:
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: data-loader
        image: your-registry.com/gekb/api:v1.0.0
        command: ["python", "-m", "gekb.scripts.load_initial_data"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: gekb-secrets
              key: database_url
        volumeMounts:
        - name: config
          mountPath: /etc/gekb
        - name: initial-data
          mountPath: /app/initial_data
      volumes:
      - name: config
        configMap:
          name: gekb-config
      - name: initial-data
        configMap:
          name: gekb-initial-data
      restartPolicy: Never
  backoffLimit: 3
EOF
```

---

## 🌐 **Phase 3: Networking and Ingress**

### **Step 3.1: TLS Certificate Setup**

#### **Create Certificate Issuer**
```yaml
# cert-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: gekb-system
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@company.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: gekb-tls
  namespace: gekb-system
spec:
  secretName: gekb-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - api.gekb.company.com
  - dashboard.gekb.company.com
```

### **Step 3.2: Ingress Configuration**

#### **Create Ingress Resource**
```yaml
# gekb-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gekb-ingress
  namespace: gekb-system
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-XSS-Protection: 1; mode=block";
      more_set_headers "Strict-Transport-Security: max-age=31536000; includeSubDomains";
spec:
  tls:
  - hosts:
    - api.gekb.company.com
    - dashboard.gekb.company.com
    secretName: gekb-tls
  rules:
  - host: api.gekb.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gekb-api-service
            port:
              number: 80
  - host: dashboard.gekb.company.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gekb-dashboard-service
            port:
              number: 80
```

---

## 📊 **Phase 4: Monitoring and Observability**

### **Step 4.1: Prometheus Configuration**

#### **Create ServiceMonitor Resources**
```yaml
# gekb-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gekb-api-monitor
  namespace: gekb-system
  labels:
    app: gekb-api
spec:
  selector:
    matchLabels:
      app: gekb-api
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gekb-worker-monitor
  namespace: gekb-system
  labels:
    app: gekb-worker
spec:
  selector:
    matchLabels:
      app: gekb-worker
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
    scrapeTimeout: 10s
```

#### **Create Grafana Dashboard**
```json
{
  "dashboard": {
    "id": null,
    "title": "GEKB System Overview",
    "tags": ["gekb", "errors", "patterns"],
    "timezone": "UTC",
    "panels": [
      {
        "id": 1,
        "title": "Error Processing Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(gekb_errors_processed_total[5m])",
            "legendFormat": "Errors/sec"
          }
        ]
      },
      {
        "id": 2,
        "title": "Pattern Match Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "gekb_pattern_matches_total / gekb_errors_processed_total * 100",
            "legendFormat": "Match Rate %"
          }
        ]
      },
      {
        "id": 3,
        "title": "Resolution Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "gekb_resolutions_successful_total / gekb_resolutions_attempted_total * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      }
    ]
  }
}
```

### **Step 4.2: Alerting Rules**

#### **Create PrometheusRule**
```yaml
# gekb-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: gekb-alerts
  namespace: gekb-system
  labels:
    app: gekb
spec:
  groups:
  - name: gekb.rules
    rules:
    - alert: GEKBHighErrorRate
      expr: rate(gekb_errors_processed_total[5m]) > 10
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error processing rate detected"
        description: "GEKB is processing {{ $value }} errors per second"
    
    - alert: GEKBLowPatternMatchRate
      expr: (gekb_pattern_matches_total / gekb_errors_processed_total * 100) < 50
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Low pattern match rate"
        description: "Pattern match rate is {{ $value }}%"
    
    - alert: GEKBDatabaseConnectionFailure
      expr: gekb_database_connections_failed_total > 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Database connection failures detected"
        description: "{{ $value }} database connection failures in the last minute"
    
    - alert: GEKBHighMemoryUsage
      expr: (container_memory_usage_bytes{pod=~"gekb-.*"} / container_spec_memory_limit_bytes) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage in GEKB pods"
        description: "Memory usage is {{ $value }}% in pod {{ $labels.pod }}"
```

---

## 🔒 **Phase 5: Security Hardening**

### **Step 5.1: Network Policies**

#### **Create Network Policies**
```yaml
# gekb-network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gekb-api-policy
  namespace: gekb-system
spec:
  podSelector:
    matchLabels:
      app: gekb-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: redis-cluster
    ports:
    - protocol: TCP
      port: 6379
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gekb-worker-policy
  namespace: gekb-system
spec:
  podSelector:
    matchLabels:
      app: gekb-worker
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: gekb-api
    ports:
    - protocol: TCP
      port: 9090
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgresql-ha
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: redis-cluster
    ports:
    - protocol: TCP
      port: 6379
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gekb-database-policy
  namespace: gekb-system
spec:
  podSelector:
    matchLabels:
      app: postgresql-ha
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: gekb-api
    - podSelector:
        matchLabels:
          app: gekb-worker
    ports:
    - protocol: TCP
      port: 5432
```

### **Step 5.2: Pod Security Standards**

#### **Create Pod Security Policy**
```yaml
# gekb-pod-security.yaml
apiVersion: v1
kind: SecurityContext
metadata:
  name: gekb-security-context
spec:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
    - ALL
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: gekb-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### **Step 5.3: Secrets Encryption**

#### **Enable Encryption at Rest**
```yaml
# encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(head -c 32 /dev/urandom | base64)
  - identity: {}
```

---

## 🧪 **Phase 6: Testing and Validation**

### **Step 6.1: Deployment Validation**

#### **Create Health Check Script**
```bash
#!/bin/bash
# deployment-health-check.sh

echo "🔍 GEKB Deployment Health Check"
echo "================================"

# Check namespace
echo "📦 Checking namespace..."
kubectl get namespace gekb-system > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Namespace gekb-system exists"
else
    echo "❌ Namespace gekb-system not found"
    exit 1
fi

# Check database
echo "🗄️ Checking PostgreSQL..."
kubectl get statefulset postgresql-ha -n gekb-system > /dev/null 2>&1
if [ $? -eq 0 ]; then
    READY_REPLICAS=$(kubectl get statefulset postgresql-ha -n gekb-system -o jsonpath='{.status.readyReplicas}')
    DESIRED_REPLICAS=$(kubectl get statefulset postgresql-ha -n gekb-system -o jsonpath='{.spec.replicas}')
    if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
        echo "✅ PostgreSQL cluster is healthy ($READY_REPLICAS/$DESIRED_REPLICAS)"
    else
        echo "⚠️ PostgreSQL cluster not fully ready ($READY_REPLICAS/$DESIRED_REPLICAS)"
    fi
else
    echo "❌ PostgreSQL statefulset not found"
fi

# Check Redis
echo "🚀 Checking Redis..."
kubectl get statefulset redis-cluster -n gekb-system > /dev/null 2>&1
if [ $? -eq 0 ]; then
    READY_REPLICAS=$(kubectl get statefulset redis-cluster -n gekb-system -o jsonpath='{.status.readyReplicas}')
    DESIRED_REPLICAS=$(kubectl get statefulset redis-cluster -n gekb-system -o jsonpath='{.spec.replicas}')
    if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
        echo "✅ Redis cluster is healthy ($READY_REPLICAS/$DESIRED_REPLICAS)"
    else
        echo "⚠️ Redis cluster not fully ready ($READY_REPLICAS/$DESIRED_REPLICAS)"
    fi
else
    echo "❌ Redis statefulset not found"
fi

# Check API deployment
echo "🌐 Checking API service..."
kubectl get deployment gekb-api -n gekb-system > /dev/null 2>&1
if [ $? -eq 0 ]; then
    READY_REPLICAS=$(kubectl get deployment gekb-api -n gekb-system -o jsonpath='{.status.readyReplicas}')
    DESIRED_REPLICAS=$(kubectl get deployment gekb-api -n gekb-system -o jsonpath='{.spec.replicas}')
    if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
        echo "✅ API service is healthy ($READY_REPLICAS/$DESIRED_REPLICAS)"
    else
        echo "⚠️ API service not fully ready ($READY_REPLICAS/$DESIRED_REPLICAS)"
    fi
else
    echo "❌ API deployment not found"
fi

# Check worker deployment
echo "⚙️ Checking Worker service..."
kubectl get deployment gekb-worker -n gekb-system > /dev/null 2>&1
if [ $? -eq 0 ]; then
    READY_REPLICAS=$(kubectl get deployment gekb-worker -n gekb-system -o jsonpath='{.status.readyReplicas}')
    DESIRED_REPLICAS=$(kubectl get deployment gekb-worker -n gekb-system -o jsonpath='{.spec.replicas}')
    if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
        echo "✅ Worker service is healthy ($READY_REPLICAS/$DESIRED_REPLICAS)"
    else
        echo "⚠️ Worker service not fully ready ($READY_REPLICAS/$DESIRED_REPLICAS)"
    fi
else
    echo "❌ Worker deployment not found"
fi

# Check ingress
echo "🌍 Checking Ingress..."
kubectl get ingress gekb-ingress -n gekb-system > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Ingress is configured"
    INGRESS_IP=$(kubectl get ingress gekb-ingress -n gekb-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$INGRESS_IP" ]; then
        echo "   📍 External IP: $INGRESS_IP"
    fi
else
    echo "❌ Ingress not found"
fi

# API endpoint test
echo "🔌 Testing API endpoint..."
API_URL="https://api.gekb.company.com/health"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ API endpoint is responding (HTTP $HTTP_STATUS)"
else
    echo "❌ API endpoint test failed (HTTP $HTTP_STATUS)"
fi

echo ""
echo "🎉 Health check completed!"
```

#### **Run Smoke Tests**
```bash
#!/bin/bash
# smoke-tests.sh

echo "🧪 GEKB Smoke Tests"
echo "==================="

API_BASE="https://api.gekb.company.com/v1"
API_KEY="your_test_api_key"

# Test error submission
echo "📤 Testing error submission..."
RESPONSE=$(curl -s -X POST "$API_BASE/errors" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "X-Project-ID: test-project" \
  -d '{
    "error": {
      "message": "Test error for deployment validation",
      "type": "TestError",
      "category": "test",
      "severity": "low"
    },
    "context": {
      "userAction": "deployment_test",
      "featureBeingWorked": "validation"
    },
    "agent": {
      "type": "test-agent",
      "version": "1.0.0",
      "persona": "Deployment Validator"
    },
    "environment": {
      "type": "production",
      "framework": "test"
    },
    "project": {
      "name": "deployment-test",
      "repository": "test/deployment",
      "branch": "main",
      "commit": "abc123"
    }
  }')

ERROR_ID=$(echo "$RESPONSE" | jq -r '.data.errorId // empty')
if [ -n "$ERROR_ID" ]; then
    echo "✅ Error submission successful (ID: $ERROR_ID)"
else
    echo "❌ Error submission failed"
    echo "$RESPONSE" | jq '.'
fi

# Test pattern search
echo "🔍 Testing pattern search..."
SEARCH_RESPONSE=$(curl -s -X GET "$API_BASE/patterns/search?category=test&limit=5" \
  -H "Authorization: Bearer $API_KEY")

PATTERN_COUNT=$(echo "$SEARCH_RESPONSE" | jq '.data.patterns | length // 0')
echo "✅ Pattern search returned $PATTERN_COUNT results"

# Test analytics
echo "📊 Testing analytics..."
ANALYTICS_RESPONSE=$(curl -s -X GET "$API_BASE/analytics/overview?time_range=1d" \
  -H "Authorization: Bearer $API_KEY")

TOTAL_ERRORS=$(echo "$ANALYTICS_RESPONSE" | jq '.data.summary.totalErrors // 0')
echo "✅ Analytics showing $TOTAL_ERRORS total errors"

echo ""
echo "🎉 Smoke tests completed!"
```

### **Step 6.2: Load Testing**

#### **Create Load Test Script**
```python
# load_test.py
import asyncio
import aiohttp
import time
import json
from typing import List, Dict
import argparse

class GEKBLoadTester:
    def __init__(self, base_url: str, api_key: str, project_id: str):
        self.base_url = base_url
        self.api_key = api_key
        self.project_id = project_id
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "X-Project-ID": project_id
        }
        
    async def submit_error(self, session: aiohttp.ClientSession, error_data: Dict) -> Dict:
        """Submit a single error and measure response time"""
        start_time = time.time()
        try:
            async with session.post(
                f"{self.base_url}/errors", 
                headers=self.headers, 
                json=error_data
            ) as response:
                end_time = time.time()
                result = await response.json()
                return {
                    "success": response.status == 200,
                    "status_code": response.status,
                    "response_time": end_time - start_time,
                    "error_id": result.get("data", {}).get("errorId") if response.status == 200 else None
                }
        except Exception as e:
            end_time = time.time()
            return {
                "success": False,
                "status_code": 0,
                "response_time": end_time - start_time,
                "error": str(e)
            }
    
    def generate_test_error(self, index: int) -> Dict:
        """Generate test error data"""
        return {
            "error": {
                "message": f"Load test error #{index}: Cannot resolve module '@/components/test/component{index}'",
                "type": "ModuleNotFoundError",
                "category": "dependency_missing",
                "severity": "medium",
                "stackTrace": [
                    f"at resolveModule (webpack://./src/test/component{index}.tsx:12:5)",
                    "at ModuleResolver.resolve (webpack://./node_modules/webpack/lib/resolve.js:201:3)"
                ],
                "affectedFiles": [f"src/test/component{index}.tsx"],
                "technology": {
                    "framework": "nextjs",
                    "library": "test-lib",
                    "component": f"component{index}"
                }
            },
            "context": {
                "userAction": "load_test",
                "featureBeingWorked": f"test_feature_{index}",
                "sessionId": f"load_test_session_{index}",
                "previousErrors": [],
                "relatedFiles": [f"src/test/component{index}.tsx"]
            },
            "agent": {
                "type": "load-test-agent",
                "version": "1.0.0",
                "persona": "Load Test Agent",
                "sessionId": f"agent_session_{index}"
            },
            "environment": {
                "type": "development",
                "nodeVersion": "18.17.0",
                "packageManager": "npm",
                "framework": "nextjs",
                "os": "linux"
            },
            "project": {
                "name": "load-test-project",
                "repository": "github.com/company/load-test",
                "branch": "main",
                "commit": f"commit{index:06d}",
                "version": "1.0.0"
            }
        }
    
    async def run_concurrent_load_test(
        self, 
        total_requests: int, 
        concurrent_users: int,
        duration_seconds: int = None
    ) -> Dict:
        """Run concurrent load test"""
        print(f"🚀 Starting load test: {total_requests} requests, {concurrent_users} concurrent users")
        
        results = []
        start_time = time.time()
        
        connector = aiohttp.TCPConnector(limit=concurrent_users * 2)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            semaphore = asyncio.Semaphore(concurrent_users)
            
            async def bounded_request(index: int):
                async with semaphore:
                    error_data = self.generate_test_error(index)
                    result = await self.submit_error(session, error_data)
                    result["request_index"] = index
                    return result
            
            # Create tasks for all requests
            if duration_seconds:
                # Time-based test
                tasks = []
                index = 0
                end_time = start_time + duration_seconds
                
                while time.time() < end_time:
                    if len(tasks) < total_requests:
                        task = asyncio.create_task(bounded_request(index))
                        tasks.append(task)
                        index += 1
                    
                    # Process completed tasks
                    done_tasks = [task for task in tasks if task.done()]
                    for task in done_tasks:
                        result = await task
                        results.append(result)
                        tasks.remove(task)
                    
                    await asyncio.sleep(0.1)
                
                # Wait for remaining tasks
                if tasks:
                    remaining_results = await asyncio.gather(*tasks)
                    results.extend(remaining_results)
            else:
                # Request-based test
                tasks = [bounded_request(i) for i in range(total_requests)]
                results = await asyncio.gather(*tasks)
        
        end_time = time.time()
        total_time = end_time - start_time
        
        # Calculate statistics
        successful_requests = [r for r in results if r["success"]]
        failed_requests = [r for r in results if not r["success"]]
        response_times = [r["response_time"] for r in successful_requests]
        
        stats = {
            "total_requests": len(results),
            "successful_requests": len(successful_requests),
            "failed_requests": len(failed_requests),
            "success_rate": len(successful_requests) / len(results) * 100 if results else 0,
            "total_duration": total_time,
            "requests_per_second": len(results) / total_time if total_time > 0 else 0,
            "avg_response_time": sum(response_times) / len(response_times) if response_times else 0,
            "min_response_time": min(response_times) if response_times else 0,
            "max_response_time": max(response_times) if response_times else 0,
            "p95_response_time": sorted(response_times)[int(len(response_times) * 0.95)] if response_times else 0,
            "p99_response_time": sorted(response_times)[int(len(response_times) * 0.99)] if response_times else 0
        }
        
        return {
            "statistics": stats,
            "results": results
        }

async def main():
    parser = argparse.ArgumentParser(description="GEKB Load Testing Tool")
    parser.add_argument("--url", default="https://api.gekb.company.com/v1", help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key for authentication")
    parser.add_argument("--project-id", default="load-test-project", help="Project ID")
    parser.add_argument("--requests", type=int, default=1000, help="Total number of requests")
    parser.add_argument("--concurrent", type=int, default=50, help="Concurrent users")
    parser.add_argument("--duration", type=int, help="Test duration in seconds")
    
    args = parser.parse_args()
    
    tester = GEKBLoadTester(args.url, args.api_key, args.project_id)
    
    result = await tester.run_concurrent_load_test(
        total_requests=args.requests,
        concurrent_users=args.concurrent,
        duration_seconds=args.duration
    )
    
    stats = result["statistics"]
    
    print("\n📊 Load Test Results:")
    print("=" * 50)
    print(f"Total Requests: {stats['total_requests']}")
    print(f"Successful: {stats['successful_requests']} ({stats['success_rate']:.2f}%)")
    print(f"Failed: {stats['failed_requests']}")
    print(f"Duration: {stats['total_duration']:.2f} seconds")
    print(f"Requests/sec: {stats['requests_per_second']:.2f}")
    print(f"Avg Response Time: {stats['avg_response_time']:.3f}s")
    print(f"Min Response Time: {stats['min_response_time']:.3f}s")
    print(f"Max Response Time: {stats['max_response_time']:.3f}s")
    print(f"95th Percentile: {stats['p95_response_time']:.3f}s")
    print(f"99th Percentile: {stats['p99_response_time']:.3f}s")

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 🔄 **Phase 7: Backup and Disaster Recovery**

### **Step 7.1: Database Backup Strategy**

#### **Create Backup CronJob**
```yaml
# gekb-backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: gekb-database-backup
  namespace: gekb-system
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: gekb-service-account
          containers:
          - name: postgres-backup
            image: postgres:14-alpine
            command:
            - /bin/bash
            - -c
            - |
              set -e
              
              # Create backup filename with timestamp
              BACKUP_FILE="gekb_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
              
              # Create database backup
              PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
                -h postgresql-ha \
                -U "$POSTGRES_USER" \
                -d gekb_production \
                --verbose \
                --no-owner \
                --no-privileges \
                | gzip > "/backups/$BACKUP_FILE"
              
              echo "Backup completed: $BACKUP_FILE"
              
              # Upload to cloud storage (example with AWS S3)
              aws s3 cp "/backups/$BACKUP_FILE" "s3://gekb-backups/database/$BACKUP_FILE"
              
              # Clean up local backup files older than 7 days
              find /backups -name "gekb_backup_*.sql.gz" -mtime +7 -delete
              
              echo "Backup process completed successfully"
            env:
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: username
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: password
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: access_key_id
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: aws-credentials
                  key: secret_access_key
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-storage-pvc
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

### **Step 7.2: Application Data Backup**

#### **Create Knowledge Base Backup**
```bash
#!/bin/bash
# gekb-knowledge-backup.sh

set -e

echo "🗄️ Starting GEKB Knowledge Base Backup"
echo "======================================"

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/gekb_backup_$BACKUP_DATE"
NAMESPACE="gekb-system"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "📦 Backing up Kubernetes resources..."

# Backup ConfigMaps
kubectl get configmaps -n $NAMESPACE -o yaml > "$BACKUP_DIR/configmaps.yaml"

# Backup Secrets (without values for security)
kubectl get secrets -n $NAMESPACE -o yaml | \
  sed 's/data:/data: {}/' > "$BACKUP_DIR/secrets-structure.yaml"

# Backup Deployments
kubectl get deployments -n $NAMESPACE -o yaml > "$BACKUP_DIR/deployments.yaml"

# Backup StatefulSets
kubectl get statefulsets -n $NAMESPACE -o yaml > "$BACKUP_DIR/statefulsets.yaml"

# Backup Services
kubectl get services -n $NAMESPACE -o yaml > "$BACKUP_DIR/services.yaml"

# Backup Ingress
kubectl get ingress -n $NAMESPACE -o yaml > "$BACKUP_DIR/ingress.yaml"

# Backup PersistentVolumeClaims
kubectl get pvc -n $NAMESPACE -o yaml > "$BACKUP_DIR/pvc.yaml"

echo "📊 Backing up analytics data..."

# Export analytics data from API
API_BASE="https://api.gekb.company.com/v1"
API_KEY="your_backup_api_key"

curl -H "Authorization: Bearer $API_KEY" \
     "$API_BASE/analytics/export?format=json&time_range=all" \
     -o "$BACKUP_DIR/analytics_export.json"

echo "📋 Backing up pattern data..."

# Export pattern data
curl -H "Authorization: Bearer $API_KEY" \
     "$API_BASE/patterns/export?format=json" \
     -o "$BACKUP_DIR/patterns_export.json"

echo "🗜️ Compressing backup..."

# Create compressed archive
tar -czf "gekb_full_backup_$BACKUP_DATE.tar.gz" -C /tmp "gekb_backup_$BACKUP_DATE"

# Upload to cloud storage
aws s3 cp "gekb_full_backup_$BACKUP_DATE.tar.gz" "s3://gekb-backups/full/gekb_full_backup_$BACKUP_DATE.tar.gz"

# Clean up
rm -rf "$BACKUP_DIR"
rm "gekb_full_backup_$BACKUP_DATE.tar.gz"

echo "✅ Backup completed successfully: gekb_full_backup_$BACKUP_DATE.tar.gz"
```

### **Step 7.3: Disaster Recovery Procedures**

#### **Create Disaster Recovery Playbook**
```markdown
# GEKB Disaster Recovery Playbook

## 🚨 Emergency Response Procedures

### Severity Levels
- **Critical**: Complete system outage, data loss risk
- **High**: Major functionality affected, degraded performance
- **Medium**: Limited functionality affected
- **Low**: Minor issues, no service impact

### Emergency Contacts
- **Primary On-Call**: +1-555-0123 (tekLeadEmail@company.com)
- **Secondary On-Call**: +1-555-0124 (sre2@company.com)
- **Management Escalation**: +1-555-0125 (director@company.com)

## 🔄 Recovery Procedures

### Database Recovery
1. **Assess damage and identify backup to restore**
2. **Stop all GEKB services to prevent data corruption**
3. **Restore database from latest backup**
4. **Verify data integrity**
5. **Restart services and validate functionality**

### Complete System Recovery
1. **Create new Kubernetes cluster if needed**
2. **Restore infrastructure components (PostgreSQL, Redis)**
3. **Deploy GEKB application from backup**
4. **Restore data from backups**
5. **Validate system functionality**
6. **Gradually restore traffic**

### Data Loss Recovery
1. **Assess scope of data loss**
2. **Identify last known good backup**
3. **Calculate recovery point objective (RPO)**
4. **Execute restoration procedures**
5. **Communicate with affected teams**
```

---

## 📈 **Phase 8: Performance Optimization**

### **Step 8.1: Database Optimization**

#### **Create Database Performance Tuning**
```sql
-- Database performance optimization
-- Execute on PostgreSQL master

-- Create indexes for common queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_errors_timestamp 
ON errors (timestamp DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_errors_project_category 
ON errors (project_id, category);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_errors_category_severity 
ON errors (category, severity);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_patterns_category 
ON error_patterns (category);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_resolutions_success 
ON resolutions (success, resolution_time);

-- Partial index for unresolved errors
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_errors_unresolved 
ON errors (timestamp) WHERE resolution_data IS NULL;

-- Composite index for analytics queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_errors_analytics 
ON errors (timestamp, category, severity, project_id);

-- Update table statistics
ANALYZE errors;
ANALYZE error_patterns;
ANALYZE resolutions;

-- Set up automatic vacuum and analyze
ALTER TABLE errors SET (
  autovacuum_vacuum_scale_factor = 0.1,
  autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE error_patterns SET (
  autovacuum_vacuum_scale_factor = 0.2,
  autovacuum_analyze_scale_factor = 0.1
);
```

### **Step 8.2: Application Performance Tuning**

#### **Create Performance Configuration**
```yaml
# gekb-performance-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gekb-performance-config
  namespace: gekb-system
data:
  performance.yml: |
    # Connection pooling
    database:
      pool_size: 20
      max_overflow: 30
      pool_timeout: 30
      pool_recycle: 3600
      pool_pre_ping: true
    
    # Redis configuration
    redis:
      connection_pool_size: 20
      socket_keepalive: true
      socket_keepalive_options:
        TCP_KEEPIDLE: 1
        TCP_KEEPINTVL: 3
        TCP_KEEPCNT: 5
    
    # Caching settings
    cache:
      pattern_cache_ttl: 3600  # 1 hour
      analytics_cache_ttl: 300  # 5 minutes
      error_context_cache_ttl: 1800  # 30 minutes
    
    # Processing optimization
    processing:
      batch_size: 100
      worker_concurrency: 10
      max_processing_time: 300
      retry_attempts: 3
      retry_delay: 5
    
    # API optimization
    api:
      request_timeout: 30
      max_request_size: 10485760  # 10MB
      rate_limit_window: 60
      compression: true
      gzip_minimum_size: 1024
```

---

## ✅ **Phase 9: Go-Live Checklist**

### **Pre-Production Checklist**
```markdown
## 🚀 GEKB Production Go-Live Checklist

### Infrastructure ✅
- [ ] Kubernetes cluster configured and hardened
- [ ] PostgreSQL high availability setup completed
- [ ] Redis cluster deployed and configured
- [ ] Load balancer and ingress configured
- [ ] TLS certificates installed and validated
- [ ] Network policies applied and tested
- [ ] Resource quotas and limits configured

### Security ✅
- [ ] All secrets properly encrypted and stored
- [ ] RBAC policies implemented and tested
- [ ] Pod security policies applied
- [ ] Network segmentation configured
- [ ] Vulnerability scanning completed
- [ ] Penetration testing performed
- [ ] Security audit completed
- [ ] Compliance requirements validated

### Application ✅
- [ ] All services deployed and healthy
- [ ] Database migrations completed successfully
- [ ] Initial data loaded and validated
- [ ] API endpoints responding correctly
- [ ] Worker processes functioning properly
- [ ] Pattern matching system operational
- [ ] Resolution engine tested and working

### Monitoring & Observability ✅
- [ ] Prometheus metrics collection working
- [ ] Grafana dashboards configured and accessible
- [ ] Alert rules configured and tested
- [ ] Log aggregation and retention configured
- [ ] Health checks and probes functioning
- [ ] Performance monitoring baselines established

### Backup & Recovery ✅
- [ ] Automated backup jobs configured and tested
- [ ] Disaster recovery procedures documented
- [ ] Backup restoration tested successfully
- [ ] Recovery time objectives (RTO) validated
- [ ] Recovery point objectives (RPO) confirmed
- [ ] Off-site backup storage configured

### Performance & Scalability ✅
- [ ] Load testing completed successfully
- [ ] Performance benchmarks established
- [ ] Auto-scaling policies configured
- [ ] Resource optimization completed
- [ ] Database performance tuned
- [ ] Caching strategies implemented

### Documentation ✅
- [ ] API documentation published and accessible
- [ ] Deployment runbooks completed
- [ ] Troubleshooting guides available
- [ ] User documentation updated
- [ ] Team training completed
- [ ] Emergency contact lists updated

### Integration Testing ✅
- [ ] End-to-end workflow testing completed
- [ ] Third-party integrations validated
- [ ] SDK compatibility verified
- [ ] Webhook functionality tested
- [ ] Authentication and authorization tested
- [ ] Data integrity validation completed
```

### **Production Deployment Execution**

#### **Final Deployment Script**
```bash
#!/bin/bash
# gekb-production-deploy.sh

set -e

echo "🚀 GEKB Production Deployment"
echo "============================"

# Configuration
NAMESPACE="gekb-system"
REGISTRY="your-registry.com"
VERSION="v1.0.0"
ENVIRONMENT="production"

# Verify prerequisites
echo "🔍 Verifying prerequisites..."

# Check kubectl access
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ kubectl not configured or cluster not accessible"
    exit 1
fi

# Check namespace
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE not found"
    exit 1
fi

# Check required secrets
REQUIRED_SECRETS=("postgresql-secret" "gekb-secrets" "aws-credentials")
for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! kubectl get secret $secret -n $NAMESPACE > /dev/null 2>&1; then
        echo "❌ Required secret $secret not found"
        exit 1
    fi
done

echo "✅ Prerequisites verified"

# Deploy infrastructure components
echo "🏗️ Deploying infrastructure components..."

# PostgreSQL
echo "   📄 Deploying PostgreSQL..."
kubectl apply -f postgresql-ha.yaml
kubectl wait --for=condition=ready pod -l app=postgresql-ha -n $NAMESPACE --timeout=300s

# Redis
echo "   🚀 Deploying Redis..."
kubectl apply -f redis-cluster.yaml
kubectl wait --for=condition=ready pod -l app=redis-cluster -n $NAMESPACE --timeout=300s

# Initialize Redis cluster
echo "   🔧 Initializing Redis cluster..."
kubectl exec -n $NAMESPACE redis-cluster-0 -- redis-cli --cluster create \
    $(kubectl get pods -l app=redis-cluster -n $NAMESPACE -o jsonpath='{range .items[*]}{.status.podIP}:6379 {end}') \
    --cluster-replicas 1 --cluster-yes

echo "✅ Infrastructure components deployed"

# Run database migrations
echo "🗄️ Running database migrations..."
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: gekb-db-migration-$(date +%s)
  namespace: $NAMESPACE
spec:
  template:
    spec:
      serviceAccountName: gekb-service-account
      containers:
      - name: migration
        image: $REGISTRY/gekb/api:$VERSION
        command: ["python", "-m", "alembic", "upgrade", "head"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: gekb-secrets
              key: database_url
        - name: ENVIRONMENT
          value: "$ENVIRONMENT"
      restartPolicy: Never
  backoffLimit: 3
EOF

# Wait for migration to complete
MIGRATION_JOB=$(kubectl get jobs -n $NAMESPACE --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl wait --for=condition=complete job/$MIGRATION_JOB -n $NAMESPACE --timeout=300s

echo "✅ Database migrations completed"

# Deploy application services
echo "🚀 Deploying application services..."

# Apply configurations
kubectl apply -f gekb-config.yaml
kubectl apply -f gekb-performance-config.yaml

# Deploy API service
echo "   🌐 Deploying API service..."
kubectl apply -f gekb-api-deployment.yaml
kubectl rollout status deployment/gekb-api -n $NAMESPACE --timeout=300s

# Deploy Worker service
echo "   ⚙️ Deploying Worker service..."
kubectl apply -f gekb-worker-deployment.yaml
kubectl rollout status deployment/gekb-worker -n $NAMESPACE --timeout=300s

# Deploy Scheduler service
echo "   📅 Deploying Scheduler service..."
kubectl apply -f gekb-scheduler-deployment.yaml
kubectl rollout status deployment/gekb-scheduler -n $NAMESPACE --timeout=300s

echo "✅ Application services deployed"

# Configure networking
echo "🌐 Configuring networking..."

# Apply network policies
kubectl apply -f gekb-network-policies.yaml

# Deploy ingress
kubectl apply -f gekb-ingress.yaml

# Wait for ingress to get IP
echo "   ⏳ Waiting for ingress to get external IP..."
for i in {1..30}; do
    INGRESS_IP=$(kubectl get ingress gekb-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_IP" ]; then
        echo "   ✅ Ingress IP: $INGRESS_IP"
        break
    fi
    echo "   ⏳ Waiting for IP assignment... ($i/30)"
    sleep 10
done

echo "✅ Networking configured"

# Set up monitoring
echo "📊 Setting up monitoring..."

# Deploy ServiceMonitors
kubectl apply -f gekb-servicemonitor.yaml

# Deploy AlertManager rules
kubectl apply -f gekb-alerts.yaml

# Import Grafana dashboard
if command -v grafana-cli &> /dev/null; then
    grafana-cli --homepath /usr/share/grafana dashboard import gekb-dashboard.json
fi

echo "✅ Monitoring configured"

# Run health checks
echo "🔍 Running health checks..."

# API health check
API_URL="https://api.gekb.company.com/health"
for i in {1..10}; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" || echo "000")
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "   ✅ API health check passed"
        break
    fi
    echo "   ⏳ API health check... ($i/10)"
    sleep 10
done

if [ "$HTTP_STATUS" != "200" ]; then
    echo "   ❌ API health check failed (HTTP $HTTP_STATUS)"
    exit 1
fi

# Database connectivity check
DB_CHECK_POD=$(kubectl run gekb-db-check --image=$REGISTRY/gekb/api:$VERSION --rm -i --restart=Never -n $NAMESPACE -- \
    python -c "
import psycopg2
import os
try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cursor = conn.cursor()
    cursor.execute('SELECT 1')
    result = cursor.fetchone()
    print('Database connection successful')
    exit(0)
except Exception as e:
    print(f'Database connection failed: {e}')
    exit(1)
" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "   ✅ Database connectivity check passed"
else
    echo "   ❌ Database connectivity check failed"
    exit 1
fi

echo "✅ Health checks completed"

# Run smoke tests
echo "🧪 Running smoke tests..."
python3 smoke-tests.py --url "https://api.gekb.company.com/v1" --api-key "$PRODUCTION_API_KEY"

echo "✅ Smoke tests completed"

# Final validation
echo "🎯 Final validation..."

# Check all pods are running
UNHEALTHY_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running -o name | wc -l)
if [ "$UNHEALTHY_PODS" -gt 0 ]; then
    echo "   ❌ $UNHEALTHY_PODS unhealthy pods found"
    kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running
    exit 1
fi

# Check all services have endpoints
SERVICES_WITHOUT_ENDPOINTS=$(kubectl get endpoints -n $NAMESPACE -o json | jq -r '.items[] | select(.subsets == null or .subsets == []) | .metadata.name' | wc -l)
if [ "$SERVICES_WITHOUT_ENDPOINTS" -gt 0 ]; then
    echo "   ❌ $SERVICES_WITHOUT_ENDPOINTS services without endpoints"
    kubectl get endpoints -n $NAMESPACE
    exit 1
fi

echo "✅ Final validation completed"

# Enable production features
echo "🔧 Enabling production features..."

# Enable auto-scaling
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gekb-api-hpa
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gekb-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gekb-worker-hpa
  namespace: $NAMESPACE
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gekb-worker
  minReplicas: 5
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75
EOF

# Set up backup jobs
kubectl apply -f gekb-backup-cronjob.yaml

echo "✅ Production features enabled"

# Deployment summary
echo ""
echo "🎉 GEKB Production Deployment Completed Successfully!"
echo "=================================================="
echo ""
echo "📊 Deployment Summary:"
echo "   • Environment: $ENVIRONMENT"
echo "   • Version: $VERSION"
echo "   • Namespace: $NAMESPACE"
echo "   • API URL: https://api.gekb.company.com"
echo "   • Dashboard URL: https://dashboard.gekb.company.com"
echo "   • Ingress IP: $INGRESS_IP"
echo ""
echo "📋 Next Steps:"
echo "   1. Update DNS records to point to ingress IP"
echo "   2. Configure monitoring alerts in your preferred system"
echo "   3. Set up log aggregation and retention policies"
echo "   4. Train your team on the new system"
echo "   5. Begin migrating existing projects to use GEKB"
echo ""
echo "📚 Documentation:"
echo "   • API Documentation: https://docs.gekb.company.com/api"
echo "   • User Guide: https://docs.gekb.company.com/guide"
echo "   • Troubleshooting: https://docs.gekb.company.com/troubleshooting"
echo ""
echo "🚨 Emergency Contacts:"
echo "   • Primary On-Call: +1-555-0123"
echo "   • Secondary On-Call: +1-555-0124"
echo "   • Escalation: +1-555-0125"
echo ""
echo "✅ GEKB is now live and ready for production use!"
```

---

## 📚 **Post-Deployment Operations**

### **Monitoring and Maintenance**

#### **Daily Operations Checklist**
```markdown
## 📋 GEKB Daily Operations Checklist

### Morning Health Check (9:00 AM)
- [ ] Check all pods are running and healthy
- [ ] Verify API endpoints are responding (200 status)
- [ ] Check database connection and performance
- [ ] Review overnight error processing metrics
- [ ] Validate backup job completion
- [ ] Check system resource utilization

### Afternoon Review (2:00 PM)
- [ ] Review error processing trends
- [ ] Check pattern matching effectiveness
- [ ] Monitor resolution success rates
- [ ] Review performance metrics and alerts
- [ ] Check auto-scaling behavior
- [ ] Validate security monitoring alerts

### Evening Wrap-up (6:00 PM)
- [ ] Review daily analytics summary
- [ ] Check for any failed jobs or processes
- [ ] Validate evening backup initiation
- [ ] Review capacity planning metrics
- [ ] Update on-call documentation if needed
```

#### **Weekly Maintenance Tasks**
```markdown
## 🔧 GEKB Weekly Maintenance Tasks

### Monday - Performance Review
- [ ] Analyze weekly performance trends
- [ ] Review auto-scaling effectiveness
- [ ] Check database query performance
- [ ] Optimize slow-running queries
- [ ] Review and adjust resource allocations

### Wednesday - Security Review
- [ ] Review security audit logs
- [ ] Check for security updates
- [ ] Validate access control policies
- [ ] Review and rotate API keys if needed
- [ ] Update security monitoring rules

### Friday - Capacity Planning
- [ ] Review storage usage trends
- [ ] Analyze error volume growth
- [ ] Plan for capacity scaling
- [ ] Review backup storage requirements
- [ ] Update resource forecasts
```

### **Troubleshooting Guide**

#### **Common Issues and Solutions**
```markdown
## 🔧 GEKB Troubleshooting Guide

### Issue: API Returns 500 Internal Server Error
**Symptoms:**
- API endpoints returning HTTP 500
- High error rates in monitoring

**Diagnosis Steps:**
1. Check API pod logs: `kubectl logs -l app=gekb-api -n gekb-system`
2. Check database connectivity
3. Review recent deployments or configuration changes
4. Check resource utilization

**Solutions:**
- Restart API pods if database connection issues
- Scale up resources if resource exhaustion
- Rollback recent changes if deployment-related
- Check database performance and optimize queries

### Issue: Worker Processing Backlog
**Symptoms:**
- Increasing queue sizes
- Slow error processing times
- Worker pod high CPU/memory usage

**Diagnosis Steps:**
1. Check worker pod metrics and logs
2. Review queue sizes in Redis
3. Check database performance
4. Analyze error processing complexity

**Solutions:**
- Scale up worker replicas
- Optimize error processing algorithms
- Increase worker resource allocations
- Add database indexes for common queries

### Issue: Pattern Matching Poor Performance
**Symptoms:**
- Low pattern match confidence scores
- Slow pattern matching responses
- High CPU usage in ML components

**Diagnosis Steps:**
1. Review pattern matching metrics
2. Check ML model performance
3. Analyze pattern database size and complexity
4. Review feature extraction performance

**Solutions:**
- Retrain ML models with recent data
- Optimize pattern database indexes
- Implement pattern caching strategies
- Scale ML processing resources
```

This comprehensive deployment guide provides everything needed to successfully deploy and operate the Global Error Knowledge Base system in production, from initial infrastructure setup through ongoing maintenance and troubleshooting.dSelector:
        matchLabels:
          app: postgresql-ha
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - po