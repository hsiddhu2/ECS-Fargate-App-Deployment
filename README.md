# ECS Fargate Demo - Python Flask Application

This project demonstrates how to deploy a Python Flask web application to Amazon ECS using AWS Fargate. It includes containerization with Docker, pushing to Amazon ECR, and setting up the complete ECS infrastructure.

## Project Structure

```
ecs-fargate-demo/
├── app/
│   ├── app.py              # Flask web application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile         # Container configuration
├── infrastructure/
│   ├── ecs-fargate-stack.yaml     # CloudFormation template
│   ├── deploy-simple.sh           # Deployment script
│   ├── destroy.sh                 # Cleanup script
│   └── parameters-template.json   # Parameters template (reference)
└── README.md
```

## Application Overview

- **Framework**: Flask (Python)
- **Container**: Docker
- **Orchestration**: Amazon ECS with Fargate
- **Load Balancer**: Application Load Balancer
- **Registry**: Amazon ECR

## Prerequisites

- AWS CLI installed and configured
- Docker installed
- AWS account with appropriate permissions
- Basic understanding of containers and AWS services

## Step-by-Step Deployment Guide

### 1. Create the Flask Application

Create `app/app.py`:
```python
from flask import Flask, jsonify 
import os 

app = Flask(__name__)

@app.route('/')
def hello_world():
    return jsonify({
        'message': os.getenv('MESSAGE', 'Hello World from ECS Fargate'),
        'version': os.getenv('VERSION', '1.0.0'),
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'container_id': os.getenv('HOSTNAME', 'unknown'),
        'region': os.getenv('AWS_REGION', 'us-west-2')
    })

@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
```

Create `app/requirements.txt`:
```
Flask==2.3.3
```

### 2. Create Dockerfile

Create `app/Dockerfile`:
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt 

COPY app.py .
EXPOSE 5000

CMD ["python", "app.py"]
```

### 3. Test Locally

```bash
cd app
docker build -t ecs-fargate-demo .
docker run -p 5000:5000 ecs-fargate-demo
```

Test: `curl http://localhost:5000`

### 4. Create ECR Repository

1. Go to Amazon ECR in AWS Console
2. Create repository: `ecs-fargate-demo`
3. Note the repository URI

### 5. Push Image to ECR

```bash
# Get login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Build and tag
docker build -t ecs-fargate-demo .
docker tag ecs-fargate-demo:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/ecs-fargate-demo:latest

# Push
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/ecs-fargate-demo:latest
```

### 6. Create ECS Infrastructure

#### Create ECS Cluster
1. Go to Amazon ECS → Clusters
2. Create cluster: `ecs-fargate-demo-cluster`
3. Select AWS Fargate (serverless)

#### Create Task Definition
1. Go to Task Definitions → Create new
2. Configuration:
   - Family: `ecs-fargate-demo-task`
   - Launch type: AWS Fargate
   - CPU: 0.25 vCPU
   - Memory: 0.5 GB
3. Container:
   - Name: `ecs-fargate-demo-container`
   - Image URI: Your ECR image URI
   - Port: 5000

#### Create Application Load Balancer
1. Go to EC2 → Load Balancers → Create ALB
2. Configuration:
   - Name: `ecs-fargate-demo-alb`
   - Internet-facing
   - Select 2+ availability zones
3. Security Group:
   - Allow HTTP (port 80) from 0.0.0.0/0
4. Target Group:
   - Type: IP addresses
   - Port: 5000
   - Health check: `/health`

#### Create ECS Service
1. Go to ECS → Clusters → Your cluster → Services
2. Configuration:
   - Launch type: Fargate
   - Task definition: Your task definition
   - Service name: `ecs-fargate-demo-service`
   - Desired tasks: 2
3. Networking:
   - Select subnets
   - Security group: Allow port 5000 from ALB
   - Public IP: Enabled
4. Load balancer: Connect to your ALB

### 7. Test Deployment

Access your application using the ALB DNS name:
```bash
curl http://your-alb-dns-name.elb.amazonaws.com
```

## CloudFormation Deployment (Infrastructure as Code)

For automated deployment using Infrastructure as Code, use the provided CloudFormation template.

### 1. Update Deployment Script Parameters

**Instruction:** Edit the parameters in `deploy-simple.sh` with your actual values:

```bash
# Parameters - Update these values as needed
PROJECT_NAME="ecs-fargate-demo"
RESOURCE_SUFFIX="cf"
IMAGE_URI="123456789012.dkr.ecr.us-west-2.amazonaws.com/ecs-fargate-demo:latest"
VPC_ID="vpc-0a1b2c3d4e5f67890"
SUBNET_IDS="subnet-0a1b2c3d4e5f67890,subnet-0b2c3d4e5f6789012"
DESIRED_COUNT="2"
CONTAINER_CPU="256"
CONTAINER_MEMORY="512"
ENVIRONMENT="development"
```

**Required Values:**
- **IMAGE_URI**: Your ECR repository URI (from ECR console)
- **VPC_ID**: Your VPC ID (from VPC console)
- **SUBNET_IDS**: At least 2 subnet IDs from different AZs (comma-separated)

### 2. Deploy Using Script

**Instruction:** Use the deployment script:

```bash
cd infrastructure
./deploy-simple.sh
```

Or with custom stack name:

```bash
./deploy-simple.sh my-custom-stack-name
```

### 3. Manual Deployment

**Instruction:** Deploy manually using AWS CLI:

```bash
aws cloudformation deploy \
    --template-file ecs-fargate-stack.yaml \
    --stack-name ecs-fargate-demo-stack \
    --parameter-overrides \
        ProjectName=ecs-fargate-demo \
        ResourceSuffix=cf \
        ImageURI=123456789012.dkr.ecr.us-west-2.amazonaws.com/ecs-fargate-demo:latest \
        VpcId=vpc-0a1b2c3d4e5f67890 \
        SubnetIds=subnet-0a1b2c3d4e5f67890,subnet-0b2c3d4e5f6789012 \
        DesiredCount=2 \
        ContainerCpu=256 \
        ContainerMemory=512 \
        Environment=development \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-west-2
```

### 4. Destroy Stack

**Instruction:** To delete the entire infrastructure:

```bash
./destroy.sh
```

Or with custom stack name:

```bash
./destroy.sh my-custom-stack-name
```

### 5. Get Application URL

**Instruction:** Get the deployed application URL:

```bash
aws cloudformation describe-stacks \
    --stack-name ecs-fargate-demo-stack \
    --region us-west-2 \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text
```

### CloudFormation Template Features

**Parameters:**
- `ProjectName` - Resource naming prefix
- `ResourceSuffix` - Suffix to avoid naming conflicts (default: cf)
- `ImageURI` - ECR image URI
- `VpcId` - Target VPC
- `SubnetIds` - Subnets for deployment
- `DesiredCount` - Number of tasks (1-10)
- `ContainerCpu` - CPU allocation (256, 512, 1024, 2048, 4096)
- `ContainerMemory` - Memory in MB (512, 1024, 2048, etc.)
- `Environment` - Environment name (development, staging, production)

**Resources Created:**
- ECS Cluster (Fargate)
- Task Definition
- ECS Service
- Application Load Balancer
- Target Group with health checks
- Security Groups
- IAM Execution Role
- CloudWatch Log Group

**Outputs:**
- Load Balancer DNS name
- Application URL
- ECS Cluster name
- Service name
- Task Definition ARN

### Update Deployment

**Instruction:** To update the application:

1. Push new image to ECR with same tag
2. Force new deployment:

```bash
aws ecs update-service \
    --cluster ecs-fargate-demo-cluster \
    --service ecs-fargate-demo-service \
    --force-new-deployment \
    --region us-west-2
```

Or redeploy the CloudFormation stack:

```bash
./deploy-simple.sh
```

## Key Concepts Learned

### Docker Concepts
- **Dockerfile**: Instructions to build container image
- **Image**: Read-only template for containers
- **Container**: Running instance of an image
- **Registry**: Storage for container images (ECR)

### ECS Concepts
- **Cluster**: Logical grouping of compute resources
- **Task Definition**: Blueprint for running containers
- **Task**: Running instance of a task definition
- **Service**: Ensures desired number of tasks are running
- **Fargate**: Serverless compute engine for containers

### Networking
- **ALB**: Distributes traffic across multiple targets
- **Target Group**: Group of targets for load balancer
- **Security Groups**: Virtual firewalls for AWS resources
- **VPC**: Virtual private cloud for network isolation

## Cost Estimation

**Monthly costs (US West 2):**
- ECS Fargate (2 tasks): ~$18/month
- Application Load Balancer: ~$16/month
- ECR Storage: ~$0.02/month
- CloudWatch Logs: ~$1-2/month

**Total: ~$35-40/month**

## Cleanup

### Manual Cleanup
To avoid charges, delete resources in this order:
1. ECS Service (scale to 0 tasks first)
2. Application Load Balancer
3. Target Groups
4. ECS Cluster
5. Task Definition (deregister)
6. ECR Repository
7. Security Groups

### CloudFormation Cleanup
To delete the entire stack:

```bash
# Using the destroy script (recommended)
./destroy.sh

# Or manually
aws cloudformation delete-stack \
    --stack-name ecs-fargate-demo-stack \
    --region us-west-2
```

**Note:** ECR repository with images must be deleted manually if not empty.

## Next Steps

- Implement CI/CD pipeline
- Add environment-specific configurations
- Set up monitoring and alerting
- Implement auto-scaling
- Add HTTPS/SSL certificates
- Use Infrastructure as Code (CloudFormation)

## Troubleshooting

**Common Issues:**
- Tasks failing to start: Check CloudWatch logs
- Health check failures: Verify `/health` endpoint
- Connection timeouts: Check security group rules
- Image pull errors: Verify ECR permissions

**Useful Commands:**
```bash
# View ECS service events
aws ecs describe-services --cluster CLUSTER_NAME --services SERVICE_NAME

# View task logs
aws logs get-log-events --log-group-name /ecs/ecs-fargate-demo --log-stream-name STREAM_NAME

# Force new deployment
aws ecs update-service --cluster CLUSTER_NAME --service SERVICE_NAME --force-new-deployment
```

## Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Docker Documentation](https://docs.docker.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)