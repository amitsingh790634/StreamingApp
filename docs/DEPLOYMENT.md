# Step-by-step deployment

Work through these steps in order. Local Kind/Minikube is enough for the Kubernetes rubric. Amazon EKS is documented in [EKS-AND-AWS.md](EKS-AND-AWS.md).

## 0. Tools

- Docker Desktop / Engine (or Colima)
- Docker Hub account
- `kubectl`, `helm` 3
- A cluster with [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/)
- Optional: AWS CLI, `eksctl`, Jenkins

## 1. Version control

This repository is a fork of [UnpredictablePrashant/StreamingApp](https://github.com/UnpredictablePrashant/StreamingApp).

```bash
git remote add upstream https://github.com/UnpredictablePrashant/StreamingApp.git
git fetch upstream
git merge upstream/main
```

## 2. Build and push images (Task 1)

Create five public Docker Hub repositories (`streaming-auth`, `streaming-stream`, `streaming-admin`, `streaming-chat`, `streaming-frontend`), then:

```bash
export DOCKERHUB_USER=amitsingh790634
export TAG=1.0.0
docker login
./scripts/build-and-push.sh
```

Equivalent manual commands (from the assignment):

```bash
docker build -t $DOCKERHUB_USER/streaming-auth:1.0.0 backend/authService
docker build -t $DOCKERHUB_USER/streaming-stream:1.0.0 -f backend/streamingService/Dockerfile backend
docker build -t $DOCKERHUB_USER/streaming-admin:1.0.0 -f backend/adminService/Dockerfile backend
docker build -t $DOCKERHUB_USER/streaming-chat:1.0.0 -f backend/chatService/Dockerfile backend
docker build -t $DOCKERHUB_USER/streaming-frontend:1.0.0 frontend
docker push $DOCKERHUB_USER/streaming-auth:1.0.0
docker push $DOCKERHUB_USER/streaming-stream:1.0.0
docker push $DOCKERHUB_USER/streaming-admin:1.0.0
docker push $DOCKERHUB_USER/streaming-chat:1.0.0
docker push $DOCKERHUB_USER/streaming-frontend:1.0.0
```

Image links:

- https://hub.docker.com/r/amitsingh790634/streaming-auth
- https://hub.docker.com/r/amitsingh790634/streaming-stream
- https://hub.docker.com/r/amitsingh790634/streaming-admin
- https://hub.docker.com/r/amitsingh790634/streaming-chat
- https://hub.docker.com/r/amitsingh790634/streaming-frontend

## 3. Cluster + Ingress

**Kind**

```bash
kind create cluster --name streamingapp
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller
```

**Minikube**

```bash
minikube start
minikube addons enable ingress
```

## 4. Install the Helm chart (Tasks 2–5)

```bash
kubectl create namespace streamingapp
helm install streamingapp ./helm/streamingapp -n streamingapp
```

Upgrade after a value or image change:

```bash
helm upgrade streamingapp ./helm/streamingapp -n streamingapp
```

Point `/etc/hosts` at the Ingress (Kind on macOS/Linux often uses `127.0.0.1` with port mapping):

```bash
echo "127.0.0.1 streamingapp.local" | sudo tee -a /etc/hosts
```

Open http://streamingapp.local

## 5. Scale and rolling update

```bash
kubectl -n streamingapp scale deploy/streaming --replicas=4
kubectl -n streamingapp rollout status deploy/streaming

helm upgrade streamingapp ./helm/streamingapp -n streamingapp --set services.auth.tag=1.0.1
kubectl -n streamingapp rollout status deploy/auth
```

Or run `./scripts/scale-and-update.sh`.

## 6. Smoke tests (Task 6)

```bash
kubectl get pods,svc,ingress -A
HOST=streamingapp.local ./scripts/smoke-test.sh
```

Manual checks:

1. Register and log in — you receive a JWT.
2. Upload a small video + thumbnail in the admin dashboard (needs AWS S3 credentials in the Secret).
3. Play the video from Browse.
4. Open chat in two tabs and confirm messages broadcast.
5. `kubectl -n streamingapp delete pod -l app.kubernetes.io/component=auth` — the Deployment recreates the pod.

## 7. Useful Helm values

```bash
# Custom host
helm upgrade streamingapp ./helm/streamingapp -n streamingapp \
  --set ingress.host=streamingapp.example.com \
  --set config.clientUrls=http://streamingapp.example.com \
  --set frontendRuntime.REACT_APP_AUTH_API_URL=http://streamingapp.example.com/api \
  --set frontendRuntime.REACT_APP_STREAMING_API_URL=http://streamingapp.example.com/api \
  --set frontendRuntime.REACT_APP_STREAMING_PUBLIC_URL=http://streamingapp.example.com \
  --set frontendRuntime.REACT_APP_ADMIN_API_URL=http://streamingapp.example.com/api/admin \
  --set frontendRuntime.REACT_APP_CHAT_API_URL=http://streamingapp.example.com/api/chat \
  --set frontendRuntime.REACT_APP_CHAT_SOCKET_URL=http://streamingapp.example.com

# Secrets (do not commit real values)
helm upgrade streamingapp ./helm/streamingapp -n streamingapp \
  --set secrets.jwtSecret='a-long-random-string' \
  --set secrets.awsAccessKeyId="$AWS_ACCESS_KEY_ID" \
  --set secrets.awsSecretAccessKey="$AWS_SECRET_ACCESS_KEY" \
  --set config.awsS3Bucket=your-bucket \
  --set config.awsRegion=ap-south-1
```

Frontend API URLs are injected at **runtime** via a ConfigMap (`runtime-config.js`). You do not need to rebuild the frontend image just to change the Ingress host.
