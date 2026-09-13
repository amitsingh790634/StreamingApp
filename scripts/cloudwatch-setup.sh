#!/usr/bin/env bash
# Enable Container Insights and create CloudWatch alarms for StreamingApp.
# Usage: CLUSTER=streamingapp-eks AWS_REGION=ap-south-1 ./scripts/cloudwatch-setup.sh
set -euo pipefail

CLUSTER="${CLUSTER:-streamingapp-eks}"
REGION="${AWS_REGION:-ap-south-1}"
SNS_TOPIC="${SNS_TOPIC:-}"

echo "==> Container Insights on ${CLUSTER}"
eksctl utils update-cluster-logging --enable-types=all --cluster "$CLUSTER" --region "$REGION" --approve || true
aws eks update-cluster-config --name "$CLUSTER" --region "$REGION" \
  --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}' \
  >/dev/null || true

echo "==> Fluent Bit (CloudWatch Logs)"
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
FluentBitHttpPort='2020'
FluentBitReadHead='Off'
kubectl create configmap fluent-bit-cluster-info \
  --from-literal=cluster.name="$CLUSTER" \
  --from-literal=http.server=On \
  --from-literal=http.port="$FluentBitHttpPort" \
  --from-literal=read.head="$FluentBitReadHead" \
  --from-literal=read.tail=On \
  --from-literal=logs.region="$REGION" \
  -n amazon-cloudwatch --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml

ALARM_ACTIONS=()
if [ -n "$SNS_TOPIC" ]; then
  ALARM_ACTIONS+=(--alarm-actions "$SNS_TOPIC")
fi

echo "==> CloudWatch alarms"
aws cloudwatch put-metric-alarm \
  --alarm-name streamingapp-node-cpu-high \
  --alarm-description "EKS node CPU above 80%" \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --region "$REGION" \
  "${ALARM_ACTIONS[@]+"${ALARM_ACTIONS[@]}"}"

aws cloudwatch put-metric-alarm \
  --alarm-name streamingapp-eks-unhealthy \
  --alarm-description "Notify when the EKS control plane is not healthy" \
  --namespace AWS/EKS \
  --metric-name cluster_failed_request_count \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ClusterName,Value="$CLUSTER" \
  --region "$REGION" \
  "${ALARM_ACTIONS[@]+"${ALARM_ACTIONS[@]}"}"

echo "CloudWatch logging and alarms configured. Logs appear under /aws/containerinsights/${CLUSTER}/"
