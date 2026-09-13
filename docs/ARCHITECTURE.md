# StreamingApp system architecture

The platform is a five-service MERN stack plus MongoDB. This repository packages that stack as a Helm chart and ships it through Jenkins to Docker Hub or Amazon ECR, then onto Kubernetes (Kind locally, or Amazon EKS).

![Architecture](architecture.svg)

## Components

| Component | Image | Port | Ingress path | Responsibility |
| --- | --- | --- | --- | --- |
| frontend | `streaming-frontend` | 80 | `/` | React SPA served by Nginx |
| authService | `streaming-auth` | 3001 | `/api`, `/api/auth`, `/health` | Register, login, JWT |
| streamingService | `streaming-stream` | 3002 | `/api/streaming` | Catalogue and playback |
| adminService | `streaming-admin` | 3003 | `/api/admin` | Signed uploads and curation |
| chatService | `streaming-chat` | 3004 | `/api/chat`, `/socket.io` | REST + Socket.IO chat |
| MongoDB | `mongo:6` | 27017 | cluster-internal | Shared datastore |

## Kubernetes objects

- **Deployment + ClusterIP Service** for each of the five app components.
- **StatefulSet + PersistentVolumeClaim + ClusterIP Service** for MongoDB (`mongo.<namespace>.svc`).
- **ConfigMap** for non-secret settings: `PORT`, `CLIENT_URLS`, `AWS_REGION`, `MONGO_URI`.
- **Secret** for `JWT_SECRET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
- **Ingress** (ingress-nginx) with one host and path-based backends, including WebSocket for chat.
- **HorizontalPodAutoscaler** (optional, on in `values-eks.yaml`).

Every Deployment uses `RollingUpdate` with `maxUnavailable: 0` and `maxSurge: 1`, plus HTTP liveness and readiness probes.

## Request flow

1. A browser hits `http://streamingapp.local`.
2. Ingress sends `/` to `frontend-svc`.
3. The SPA reads `/runtime-config.js` (mounted from a ConfigMap) so API URLs match the Ingress host.
4. Login posts to `/api/login` → `auth-svc`.
5. Browse calls `/api/streaming/videos` → `streaming-svc`.
6. Admin uploads go to `/api/admin` → `admin-svc` (S3 signed URLs when AWS keys are set).
7. Chat REST uses `/api/chat`; Socket.IO uses `/socket.io` → `chat-svc`.
8. All backends share `mongodb://mongo:27017/streamingapp`.

## CI / CD

```
GitHub (this fork)
        │  webhook
        ▼
Jenkins (academic instance or self-hosted EC2)
        │  docker build
        ▼
Docker Hub  or  Amazon ECR
        │  helm upgrade --set tag=...
        ▼
Kubernetes (Kind / Minikube / EKS)
```

## Observability

On EKS, Container Insights + Fluent Bit ship pod logs to CloudWatch Logs. Metric alarms (CPU, failed API requests) can publish to SNS. The bonus ChatOps step connects those SNS topics to Slack, Teams, or Telegram.
