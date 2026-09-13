#!/usr/bin/env bash
# Install Jenkins, Docker, AWS CLI, and kubectl on Amazon Linux 2023 / Ubuntu.
# Run on a fresh EC2 instance (t3.medium+, 20 GB disk, ports 22 and 8080).
set -euo pipefail

if command -v dnf >/dev/null 2>&1; then
  sudo dnf update -y
  sudo dnf install -y java-17-amazon-corretto git docker
  sudo dnf install -y fontconfig
  sudo yum install -y wget
  sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
  sudo dnf install -y jenkins
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y openjdk-17-jdk git curl unzip apt-transport-https ca-certificates gnupg
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list
  sudo apt-get update
  sudo apt-get install -y jenkins docker.io
else
  echo "Unsupported OS. Use Amazon Linux 2023 or Ubuntu 22.04."
  exit 1
fi

sudo systemctl enable --now docker
sudo usermod -aG docker jenkins || true
sudo usermod -aG docker "$USER" || true

# AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
fi

# kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi

sudo systemctl enable --now jenkins
echo "Jenkins is starting. Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true
echo
echo "Open http://$(curl -s http://checkip.amazonaws.com):8080"
echo "Install plugins from jenkins/plugins.txt, then add credentials:"
echo "  dockerhub          — Docker Hub username/password"
echo "  aws-ecr            — AWS access key (if using ECR pipeline)"
echo "  github-pat         — GitHub personal access token for webhooks"
