# Vlearn submission

**GitHub repository:** https://github.com/amitsingh790634/StreamingApp

This file is what you upload to Vlearn (text / Word / PDF). The repository already contains the Helm chart, Jenkins pipelines, AWS/EKS scripts, and documentation.

## Docker Hub images (tag `1.0.0`)

- https://hub.docker.com/r/amitsingh790634/streaming-auth
- https://hub.docker.com/r/amitsingh790634/streaming-stream
- https://hub.docker.com/r/amitsingh790634/streaming-admin
- https://hub.docker.com/r/amitsingh790634/streaming-chat
- https://hub.docker.com/r/amitsingh790634/streaming-frontend

## Install

```bash
helm install streamingapp ./helm/streamingapp -n streamingapp --create-namespace
# then open http://streamingapp.local
```
