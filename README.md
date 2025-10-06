## Deploying High-Availability Two-Tier AWS Architecture with Terraform and Jenkins

Project Overview:
I designed and automated the deployment of a robust, high-availability (HA) two-tier AWS architecture using Terraform (Infrastructure as Code) and Jenkins CI/CD. This project ensures a resilient and scalable infrastructure composed of a public-facing web tier and a secure, private database tier, demonstrating expertise in automated cloud provisioning and continuous deployment.

## Architecture & Deployment Workflow:
The AWS architecture was meticulously designed for fault tolerance and scalability, deployed within the us-east-1 region, and includes:

    VPC Configuration: Custom CIDR block for network isolation, configured with an Internet Gateway for outbound connectivity.

    Subnets & Availability Zones: Four subnets strategically distributed across two Availability Zones (two public, two private) for high availability.

    Web Tier (Public):

        Application Load Balancer (ALB): Distributes incoming user requests across web servers.

        EC2 Instances: Two EC2 instances (web servers) hosted in separate public subnets within distinct AZs for redundancy.

        Security Group: Custom security group configured to allow appropriate inbound traffic (e.g., HTTP/HTTPS) to the ALB and EC2 instances.

    Database Tier (Private):

        RDS Database: A secure, highly available RDS instance deployed in private subnets across distinct AZs, isolated from direct internet access.

        Security Group: Custom security group restricting access only from the web tier EC2 instances.

    Routing: Configured route tables to manage traffic flow between subnets and the Internet Gateway.

The deployment process is fully automated via a Jenkins CI/CD pipeline:

    Terraform HCL: Infrastructure configuration is managed as code (HCL) and hosted in a GitHub repository.

    Jenkins Trigger: A Jenkins pipeline is triggered upon changes or manually.

    Code Clone: Jenkins clones the Terraform configuration code from GitHub.

    Terraform Apply: Jenkins executes terraform apply to provision and manage the entire AWS infrastructure as defined by the HCL.

## Objectives Achieved:

    Designed and deployed a fault-tolerant, high-availability two-tier architecture on AWS.

    Automated infrastructure provisioning using Terraform (IaC) for consistency and version control.

    Integrated Jenkins to enable continuous, automated deployment of infrastructure from GitHub.

    Implemented robust networking (VPC, subnets, routing) and security best practices (security groups) for both tiers.
    Part 1: Committing Terraform configuration code HCL in GitHub.
    Part 2: Deploying the application to the AWS infrastructure using Jenkins through the HCL code in GitHub.

<img width="1225" height="490" alt="terraform_jenkins_aws" src="https://github.com/user-attachments/assets/a9e47749-7fde-4284-9c7d-c0b3e8947e04" />
<img width="673" height="404" alt="awsArchitecture" src="https://github.com/user-attachments/assets/aba897e6-2d88-48e2-8dfb-7ca9cc374ca9" />
