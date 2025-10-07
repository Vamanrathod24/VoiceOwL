## 🧩 Prerequisites

Before running this project locally or configuring the pipeline, ensure you have these tools installed:

| Tool | Purpose | Installation |
|------|----------|---------------|
| **Node.js & npm** | To build and run the Node.js app | [Download](https://nodejs.org/) |
| **Docker** | To containerize and push app images | [Install Docker](https://docs.docker.com/get-docker/) |
| **Terraform** | To provision AWS infrastructure | [Install Terraform](https://developer.hashicorp.com/terraform/downloads) |
| **AWS CLI** | To interact with AWS services | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **kubectl** | To interact with Kubernetes clusters | [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) |

After installing AWS CLI, configure your credentials:
```bash
aws configure

Project Structure

VoiceOwL/
├── app/                     # Node.js application
│   ├── Dockerfile           # Dockerfile for Node.js app
│   ├── package.json
│   └── server.js
├── k8s/                     # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── infra/                   # Terraform IaC for AWS EKS
│   ├── main.tf
└── .github/
    └── workflows/
        └── ci-cd.yml        # GitHub Actions pipeline

Teck Stack        

| Category         | Tools            |
| ---------------- | ---------------- |
| Application      | Node.js          |
| Containerization | Docker           |
| Infrastructure   | Terraform        |
| Orchestration    | Kubernetes (EKS) |
| CI/CD            | GitHub Actions   |
| Security         | Semgrep          |
| Cloud Provider   | AWS              |

Local Setup

git clone https://github.com/Vamanrathod24/VoiceOwL.git
cd VoiceOwL

cd app
npm install

docker build -t voiceowl-app .
docker run -p 3000:3000 voiceowl-app

Terraform Setup for EKS

cd infra
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

Kubernetes Deployment

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

kubectl get pods
kubectl get svc

Access application

kubectl get nodes -o wide
kubectl get svc
https://100.25.246.20:30080/



