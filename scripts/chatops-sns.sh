#!/usr/bin/env bash
# Bonus ChatOps: SNS topics for deploy success / failure, optional email or Slack HTTPS.
# Usage: EMAIL=you@example.com SLACK_HTTPS_ENDPOINT=https://hooks.slack.com/services/XXX ./scripts/chatops-sns.sh
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
PREFIX="${SNS_PREFIX:-streamingapp}"

SUCCESS_ARN="$(aws sns create-topic --name "${PREFIX}-deploy-success" --region "$REGION" --query TopicArn --output text)"
FAILURE_ARN="$(aws sns create-topic --name "${PREFIX}-deploy-failure" --region "$REGION" --query TopicArn --output text)"

echo "Success topic: $SUCCESS_ARN"
echo "Failure topic: $FAILURE_ARN"

if [ -n "${EMAIL:-}" ]; then
  aws sns subscribe --topic-arn "$SUCCESS_ARN" --protocol email --notification-endpoint "$EMAIL" --region "$REGION"
  aws sns subscribe --topic-arn "$FAILURE_ARN" --protocol email --notification-endpoint "$EMAIL" --region "$REGION"
  echo "Confirm the subscription email sent to ${EMAIL}"
fi

if [ -n "${SLACK_HTTPS_ENDPOINT:-}" ]; then
  aws sns subscribe --topic-arn "$SUCCESS_ARN" --protocol https --notification-endpoint "$SLACK_HTTPS_ENDPOINT" --region "$REGION"
  aws sns subscribe --topic-arn "$FAILURE_ARN" --protocol https --notification-endpoint "$SLACK_HTTPS_ENDPOINT" --region "$REGION"
  echo "Slack/Teams HTTPS subscriptions created. Confirm them in the messaging app."
fi

echo
echo "Export these in Jenkins as SNS_TOPIC_ARN (or create two post-actions):"
echo "  export SNS_TOPIC_ARN=${SUCCESS_ARN}"
echo
echo "AWS Chatbot (recommended for Slack/Teams):"
echo "  1. Open AWS Chatbot in the console"
echo "  2. Configure a Slack / Teams workspace"
echo "  3. Bind both SNS topics to the channel"
echo "  4. Telegram is supported via an HTTPS subscription to a bot webhook"
