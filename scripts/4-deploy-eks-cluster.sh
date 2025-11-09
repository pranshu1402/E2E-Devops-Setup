#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
K8_DIR="${ROOT_DIR}/k8s"
TAG=${1:-latest}
ECR_REGISTRY=${2:-}
DOCKER_REPO_NAME=${3:-g5_slabai}

# Load configuration from config.env file if available
if [ -f "${ROOT_DIR}/config.env" ]; then
    set -a  # Auto-export all variables
    source "${ROOT_DIR}/config.env"
    set +a  # Turn off auto-export
    echo -e "${GREEN}✅ Configuration loaded from ${ROOT_DIR}/config.env${NC}"
fi

if [ -z "$ECR_REGISTRY" || -z "$DOCKER_REPO_NAME" ]; then
    echo -e "${RED}❌ ECR_REGISTRY or DOCKER_REPO_NAME is not set. Please set them in config.env or pass as arguments.${NC}"
    echo -e "${YELLOW}Usage: $0 [TAG] [ECR_REGISTRY] [DOCKER_REPO_NAME]${NC}"
    exit 1
fi

echo ""
echo "⚙️  Configuring kubectl for EKS cluster"
echo "==============================="

echo -e "${YELLOW}Updating kubeconfig for EKS cluster...${NC}"
aws eks update-kubeconfig --region us-west-2 --name app-dev

echo -e "${YELLOW}Testing cluster connectivity...${NC}"
kubectl get nodes

echo -e "${GREEN}✅ kubectl configured successfully ✓${NC}"

# Check if kubectl is configured for EKS
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ kubectl is not configured for EKS cluster. Please run 'aws eks update-kubeconfig' first.${NC}"
    exit 1
fi

# Verify we're connected to EKS (not local cluster)
CLUSTER_INFO=$(kubectl cluster-info | head -1)
if [[ $CLUSTER_INFO == *"https://kubernetes.docker.internal"* ]] || [[ $CLUSTER_INFO == *"127.0.0.1"* ]]; then
    echo -e "${RED}❌ kubectl is pointing to local cluster, not EKS. Please configure for EKS cluster.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ kubectl is configured for EKS cluster${NC}"
echo -e "${BLUE}Cluster Info: ${CLUSTER_INFO}${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    echo -e "${YELLOW}   Visit: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All EKS Deployment Prerequisites are met!${NC}"
echo ""

echo -e "${BLUE}🚀 Starting EKS deployment...${NC}"

# Install AWS Load Balancer Controller (for EKS)
echo -e "${YELLOW}🔧 Installing AWS Load Balancer Controller...${NC}"
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Install envsubst if not available
if ! command -v envsubst &> /dev/null; then
  echo -e "${YELLOW}🔧 Installing envsubst...${NC}"
  # OS detection for cross-platform compatibility
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
      sudo apt-get install -y gettext-base
    elif command -v yum &> /dev/null; then
      sudo yum install -y gettext
    elif command -v dnf &> /dev/null; then
      sudo dnf install -y gettext
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
      brew install gettext
    fi
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    echo -e "${YELLOW}Please install Git for Windows which includes envsubst${NC}"
    echo -e "${YELLOW}Or install gettext from: https://www.gnu.org/software/gettext/${NC}"
  fi
fi

# Export variables for envsubst
export ECR_REGISTRY
export TAG
export DOCKER_REPO_NAME
export AWS_ACCOUNT_ID
export AWS_REGION

# Create namespace
echo -e "${YELLOW}📦 Creating namespace...${NC}"
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/namespace.yaml | kubectl apply -f -

# Apply ConfigMap and Secrets
echo -e "${YELLOW}🔐 Applying ConfigMap and Secrets...${NC}"
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/configmap.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/secret.yaml | kubectl apply -f -

# Deploy databases
echo -e "${YELLOW}🗄️  Deploying databases...${NC}"
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/mongodb.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/redis.yaml | kubectl apply -f -

# Wait for databases to be ready
echo -e "${YELLOW}⏳ Waiting for databases to be ready...${NC}"
kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=mongodb \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=300s

# Deploy backend services
echo -e "${YELLOW}🔧 Deploying backend services...${NC}"
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/payment-service.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/project-service.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/user-service.yaml | kubectl apply -f -

# Deploy frontend
echo -e "${YELLOW}🌐 Deploying frontend...${NC}"
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/frontend-service.yaml | kubectl apply -f -

# Deploy ingress
echo -e "${YELLOW}🚪 Deploying ingress...${NC}"
envsubst '$ECR_REGISTRY $TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/ingress.yaml | kubectl apply -f -

# Wait for all pods to be ready
echo -e "${YELLOW}⏳ Waiting for all services to be ready...${NC}"
kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=payment-service \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=project-service \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=user-service \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=300s

echo -e "${GREEN}🎉 EKS Deployment completed successfully!${NC}"
echo ""

# Get Load Balancer URL
echo -e "${YELLOW}🔍 Getting Load Balancer URL...${NC}"
LB_URL=$(kubectl get ingress -n ${DOCKER_REPO_NAME} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")

echo -e "${GREEN}📋 Service URLs:${NC}"
if [ "$LB_URL" != "Pending..." ] && [ -n "$LB_URL" ]; then
    echo -e "  • Frontend: http://${LB_URL}"
    echo -e "  • Payment Service: http://${LB_URL}/api/payment"
    echo -e "  • Project Service: http://${LB_URL}/api/project"
    echo -e "  • User Service: http://${LB_URL}/api/user"
else
    echo -e "  • Load Balancer URL: ${YELLOW}Pending (check in a few minutes)${NC}"
    echo -e "  • Run: kubectl get ingress -n ${DOCKER_REPO_NAME} to get the URL"
fi

echo ""
echo -e "${GREEN}🔍 Check deployment status:${NC}"
echo -e "  kubectl get pods -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl get services -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl get ingress -n ${DOCKER_REPO_NAME}"
echo ""
echo -e "${GREEN}📊 Monitor logs:${NC}"
echo -e "  kubectl logs -f deployment/payment-service -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl logs -f deployment/project-service -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl logs -f deployment/user-service -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl logs -f deployment/frontend -n ${DOCKER_REPO_NAME}"
echo ""
echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
echo -e "  kubectl describe pods -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl get events -n ${DOCKER_REPO_NAME} --sort-by='.lastTimestamp'"
