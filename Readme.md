# Devops - Capstone Project

## Problem Statement
Modern DevOps teams need a robust, automated CI/CD pipeline that not only builds and deploys
applications consistently but also ensures container security and Kubernetes cluster reliability. This
project sets up an end-to-end pipeline that covers infrastructure provisioning (Terraform),
configuration management (Ansible), containerization (Docker), CI/CD orchestration (Jenkins),
secure image scanning (Trivy), application deployment on AWS EKS, and automated cluster health
monitoring & self-healing using Prometheus and custom scripts.
Detailed Description: [End-to-End DevOps Pipeline Project](./project_guides/End_to_End_DevOps_Pipeline_Project.pdf)
---------------------------

# Architecture:
---------------------------
Diagram: [Architecture Diagram](./project_guides/architecture_diagram/Architecture%20Diagram.png)

## Project Goals
1. Design and implement an automated CI/CD pipeline on AWS.
2. Provision infrastructure using Terraform (VPC, subnets, EKS, EC2).
3. Automate configuration using Ansible.
4. Build and scan Docker images for vulnerabilities before deploying.
5. Deploy applications on Kubernetes (AWS EKS) for scalability and high availability.
6. Automate health checks and self-healing for Kubernetes clusters.
7. Set up real-time monitoring and alerting with Prometheus, Grafana, and Slack notifications.
---------------------------

## Key Tools & Technologies
- CI/CD: Jenkins, GitHub
- Containerization: Docker, AWS ECR
- Infrastructure as Code: Terraform
- Configuration Management: Ansible
- Orchestration: Kubernetes (AWS EKS)
- Image Security: Trivy (Container Vulnerability Scanner)
- Monitoring & Alerts: Prometheus, Grafana, Alertmanager, Slack API
- Programming/Scripting: Bash, Python (for health checker)
- Other AWS Services: CDN, EC2, ECS + Fargate
- Database: MONGO DB (Atlas Cloud)
---------------------------

## Setup Scripts & Guides
- Project Structure: [Project Structure](./project_guides/PROJECT_STRUCTURE.md)
- Architecture: [Architecture Assets](./project_guides/architecture_diagram)
- Environment Config Management: [Configuration Management](./project_guides/CONFIGURATION.md)
- Infra: 
    Prerequisites: AWS CLI + Terraform Setup
    Setup Script Via Terraform: [`deploy-infrastructure.sh`](./scripts/deploy-infrastructure.sh)
    Guide: [Terraform Deployment Guide](./project_guides/TERRAFORM_DEPLOYMENT.md)
- Deployment:
    Prerequisites: Setup Jenkins
    Guide: [Deployment Setup Guide](./project_guides/SETUP_GUIDE.md)
    Setup Script: [`complete_deployment.sh`](./complete_deployment.sh)