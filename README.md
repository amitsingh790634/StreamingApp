# StreamingApp — Container Orchestration

Fork of [UnpredictablePrashant/StreamingApp](https://github.com/UnpredictablePrashant/StreamingApp) with Docker images, a Helm chart, Jenkins CI, EKS/ECR scripts, and CloudWatch/ChatOps extras.

**Repository:** https://github.com/amitsingh790634/StreamingApp

![Architecture](docs/architecture.svg)

## Quick install

```bash
# 1. Images (once Docker Hub repos exist)
export DOCKERHUB_USER=amitsingh790634
export TAG=1.0.0
docker login
./scripts/build-and-push.sh

# 2. Cluster with ingress-nginx already running
kubectl create namespace streamingapp
helm install streamingapp ./helm/streamingapp -n streamingapp

# 3. Reach the app
echo "127.0.0.1 streamingapp.local" | sudo tee -a /etc/hosts
open http://streamingapp.local
```

Upgrade and scale:

```bash
helm upgrade streamingapp ./helm/streamingapp -n streamingapp
kubectl -n streamingapp scale deploy/streaming --replicas=4
kubectl -n streamingapp rollout status deploy/streaming
helm upgrade streamingapp ./helm/streamingapp -n streamingapp --set services.auth.tag=1.0.1
kubectl -n streamingapp rollout status deploy/auth
```

Ingress routes on host `streamingapp.local`:

| Path | Service | Port |
| --- | --- | --- |
| `/` | frontend-svc | 80 |
| `/api`, `/api/auth` | auth-svc | 3001 |
| `/api/streaming` | streaming-svc | 3002 |
| `/api/admin` | admin-svc | 3003 |
| `/api/chat`, `/socket.io` | chat-svc | 3004 |

## Docker Hub images

| Service | Image |
| --- | --- |
| auth | https://hub.docker.com/r/amitsingh790634/streaming-auth |
| streaming | https://hub.docker.com/r/amitsingh790634/streaming-stream |
| admin | https://hub.docker.com/r/amitsingh790634/streaming-admin |
| chat | https://hub.docker.com/r/amitsingh790634/streaming-chat |
| frontend | https://hub.docker.com/r/amitsingh790634/streaming-frontend |

Tag every image `1.0.0` (and the Jenkins build number).

## Repository layout

```
helm/streamingapp/          Helm chart (all values templated)
jenkins/                    ECR pipeline + plugin list
Jenkinsfile                 Docker Hub CI pipeline
scripts/                    build, ECR, EKS, deploy, smoke, CloudWatch, ChatOps
infra/eks-cluster.yaml      eksctl cluster spec
monitoring/                 Fluent Bit reference values
docs/                       architecture, deploy, Jenkins, EKS, monitoring
VLEARN-SUBMISSION.txt       file to upload on Vlearn
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Deployment (Kind / Minikube / Helm)](docs/DEPLOYMENT.md)
- [Jenkins CI](docs/JENKINS-CI.md)
- [AWS, ECR, and EKS](docs/EKS-AND-AWS.md)
- [Monitoring, logging, ChatOps](docs/MONITORING.md)
- [Production notes](docs/PRODUCTION-NOTES.md)

## Application services

| Service | Port | Description |
| --- | --- | --- |
| `authService` | 3001 | User authentication, registration, JWT issuance |
| `streamingService` | 3002 | Video catalogue, S3 playback endpoints, public APIs |
| `adminService` | 3003 | Dedicated admin microservice for asset management and uploads |
| `chatService` | 3004 | Websocket + REST chat for live watch parties |
| `frontend` | 3000 → 80 | React SPA served by Nginx |
| `mongo` | 27017 | Shared MongoDB instance |

## Docker Compose (local, no Kubernetes)

```bash
cp .env.example .env
docker compose up --build
# http://localhost:3000
```

## Environment configuration

Create an `.env` for each service (or export variables before running). All services accept the standard AWS credentials for S3 access.

### Auth Service (`backend/authService/.env`)

```ini
PORT=3001
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=
```

### Streaming Service (`backend/streamingService/.env`)

```ini
PORT=3002
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=
AWS_CDN_URL=
STREAMING_PUBLIC_URL=http://localhost:3002
```

### Admin Service (`backend/adminService/.env`)

```ini
PORT=3003
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=ap-south-1
AWS_S3_BUCKET=
```

### Chat Service (`backend/chatService/.env`)

```ini
PORT=3004
MONGO_URI=mongodb://localhost:27017/streamingapp
JWT_SECRET=changeme
CLIENT_URLS=http://localhost:3000
```

### Frontend (`frontend/.env` or Docker build args)

```ini
REACT_APP_AUTH_API_URL=http://localhost:3001/api
REACT_APP_STREAMING_API_URL=http://localhost:3002/api
REACT_APP_STREAMING_PUBLIC_URL=http://localhost:3002
REACT_APP_ADMIN_API_URL=http://localhost:3003/api/admin
REACT_APP_CHAT_API_URL=http://localhost:3004/api/chat
REACT_APP_CHAT_SOCKET_URL=http://localhost:3004
```

On Kubernetes these frontend URLs come from Helm (`frontendRuntime.*`) and are mounted as `/runtime-config.js`. You do not need a rebuild to change the Ingress host.

## Smoke tests

```bash
kubectl get pods,svc,ingress -A
HOST=streamingapp.local ./scripts/smoke-test.sh
```

Recommended UI checks: register + login (JWT), admin upload, playback from Browse, chat across two tabs, delete a pod and confirm it self-heals.

## License

MIT © StreamFlix Team
