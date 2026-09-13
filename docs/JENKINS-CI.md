# Continuous Integration with Jenkins

Two pipelines ship in this repo:

| File | Registry | When to use |
| --- | --- | --- |
| `Jenkinsfile` (repo root) | Docker Hub | Default for the Kubernetes assignment rubric |
| `jenkins/Jenkinsfile.ecr` | Amazon ECR | Graded project path that deploys to EKS |

Both build all five images on every commit and push version `1.0.0` plus the Jenkins build number.

## Option A — Academic Jenkins

URL: `https://jenkinsacademics.herovired.com/`

1. Log in with the credentials provided by the program.
2. New Item → Multibranch Pipeline or Pipeline.
3. Point SCM at `https://github.com/amitsingh790634/StreamingApp.git`.
4. Script path: `Jenkinsfile`.
5. Add credentials:
   - `dockerhub` — Username/password (Docker Hub)
6. Enable GitHub webhook: `http://<jenkins>/github-webhook/` on the repository.

The academic instance is shared. Prefer a job name that includes your roll number so it does not collide with classmates.

## Option B — Jenkins on EC2

```bash
# on a fresh Amazon Linux 2023 / Ubuntu instance (ports 22 + 8080)
chmod +x scripts/setup-jenkins-ec2.sh
./scripts/setup-jenkins-ec2.sh
```

Install plugins listed in `jenkins/plugins.txt` (Git, Docker Pipeline, Credentials Binding, Amazon ECR, AWS Credentials).

Add credentials:

| ID | Kind | Used by |
| --- | --- | --- |
| `dockerhub` | Username/password | `Jenkinsfile` |
| `aws-ecr` | AWS access key | `jenkins/Jenkinsfile.ecr` |
| `aws-account-id` | Secret text | ECR registry hostname |
| `github-pat` | Secret text | Private repo checkout / webhooks |

Configure GitHub → Settings → Webhooks → `http://<ec2-public-ip>:8080/github-webhook/` for push events. That satisfies “trigger automatically on new commits”.

## GitHub webhook payload URL

```
http://<jenkins-host>:8080/github-webhook/
```

Content type: `application/json`. Events: `Just the push event`.

## What the pipeline does

1. Checkout the commit.
2. `docker build` each service (correct build context for streaming/admin/chat).
3. Tag `:1.0.0` and `:${BUILD_NUMBER}`.
4. `docker login` + `docker push`.
5. Optional SNS publish when `SNS_TOPIC_ARN` is set on the agent (ChatOps bonus).
