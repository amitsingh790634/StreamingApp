# AWS environment, ECR, and EKS

This path covers the graded-project workflow: AWS CLI → ECR images → EKS cluster → Helm.

## 1. AWS CLI

```bash
# macOS
brew install awscli eksctl

aws configure
# AWS Access Key ID / Secret / region (ap-south-1 recommended)
aws sts get-caller-identity
```

Required IAM capabilities (lab account): `AmazonEC2FullAccess`, `IAMFullAccess`, `AmazonEKSClusterPolicy` / `eksctl` starter policy, `AmazonEC2ContainerRegistryFullAccess`, `CloudWatchFullAccess`, `AmazonSNSFullAccess`, `AmazonS3FullAccess` (for video objects).

## 2. Amazon ECR — one repository per component

```bash
export AWS_REGION=ap-south-1
./scripts/create-ecr-repos.sh
./scripts/build-and-push-ecr.sh
```

That creates and fills:

- `streaming-auth`
- `streaming-stream`
- `streaming-admin`
- `streaming-chat`
- `streaming-frontend`

Jenkins can do the same work with `jenkins/Jenkinsfile.ecr`.

## 3. Create the EKS cluster

```bash
./scripts/create-eks-cluster.sh streamingapp-eks
```

The cluster spec lives in `infra/eks-cluster.yaml`: Kubernetes 1.30, three `t3.medium` nodes, OIDC, EBS CSI, and control-plane CloudWatch logs.

Cost warning: tear the cluster down after the demo:

```bash
eksctl delete cluster -f infra/eks-cluster.yaml
```

## 4. Deploy with Helm

```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT}.dkr.ecr.ap-south-1.amazonaws.com"

# Grant nodes permission to pull (eksctl imageBuilder addon already covers this)

kubectl create namespace streamingapp
helm upgrade --install streamingapp ./helm/streamingapp \
  -n streamingapp \
  -f helm/streamingapp/values-eks.yaml \
  --set imageRegistry="$REGISTRY" \
  --set ingress.host=streamingapp.example.com \
  --wait
```

Fetch the Ingress load-balancer hostname:

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller
# Create a Route53 CNAME (or /etc/hosts) from streamingapp.example.com to that NLB
```

Allow the EKS nodes to pull from ECR (if you did not use the imageBuilder policy):

```bash
eksctl create iamidentitymapping --cluster streamingapp-eks --region ap-south-1 \
  --arn arn:aws:iam::<account>:role/<node-instance-role> --group system:nodes
```

Nodes created by the bundled `eksctl` file already have ECR pull rights.

## 5. S3 for video uploads

```bash
aws s3 mb s3://streamingapp-<yourname>-media --region ap-south-1
helm upgrade streamingapp ./helm/streamingapp -n streamingapp --reuse-values \
  --set config.awsS3Bucket=streamingapp-<yourname>-media \
  --set secrets.awsAccessKeyId="$AWS_ACCESS_KEY_ID" \
  --set secrets.awsSecretAccessKey="$AWS_SECRET_ACCESS_KEY"
```

Without S3 the catalogue and auth still work; playback and admin uploads need a bucket.
