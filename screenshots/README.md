# Submission screenshots

Capture these after `helm install` and keep them in this folder (or attach them in Vlearn).

1. `kubectl-get.png` — output of `kubectl get pods,svc,ingress -A` with every Deployment Ready.
2. `login.png` — successful login on http://streamingapp.local/login.
3. `upload.png` — one video + thumbnail created in the admin dashboard.
4. `chat-tab-1.png` and `chat-tab-2.png` — the same message visible in two browser tabs.
5. `self-heal.png` — after `kubectl delete pod` the replacement pod is Running.

Commands that produce the cluster evidence:

```bash
kubectl get pods,svc,ingress -A
kubectl -n streamingapp get deploy
kubectl -n streamingapp rollout status deploy/auth
```
