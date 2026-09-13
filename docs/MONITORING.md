# Monitoring, logging, and ChatOps

## CloudWatch metrics and alarms

```bash
export CLUSTER=streamingapp-eks
export AWS_REGION=ap-south-1
export SNS_TOPIC=arn:aws:sns:ap-south-1:123456789012:streamingapp-deploy-failure
./scripts/cloudwatch-setup.sh
```

What this enables:

- EKS control-plane logs (`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`).
- Container Insights namespace + Fluent Bit DaemonSet, which tails container logs into `/aws/containerinsights/<cluster>/`.
- Alarms:
  - `streamingapp-node-cpu-high` — EC2 CPU > 80% for 10 minutes.
  - `streamingapp-eks-unhealthy` — elevated EKS failed request count.

Application logs are also written to stdout by Express (`morgan` on admin/chat). Fluent Bit ships those streams automatically — you do not change application code.

## Local / Kind equivalent

```bash
kubectl -n streamingapp logs deploy/auth --tail=100
kubectl -n streamingapp logs deploy/streaming --tail=100
kubectl top pods -n streamingapp   # needs metrics-server
```

## Bonus — ChatOps (Step 9)

```bash
export EMAIL=you@example.com
# optional Slack incoming webhook or Telegram bot HTTPS endpoint
export SLACK_HTTPS_ENDPOINT=https://hooks.slack.com/services/T.../B.../xxx
./scripts/chatops-sns.sh
```

The script creates:

- `streamingapp-deploy-success`
- `streamingapp-deploy-failure`

Subscribe email for a quick demo. For Slack or Microsoft Teams, attach the topics to **AWS Chatbot**. For Telegram, subscribe the HTTPS protocol to your bot webhook.

Set `SNS_TOPIC_ARN` on the Jenkins agent so the pipeline publishes a message on success and on failure.
