#!/bin/bash

# Simple ECS Fargate CloudFormation Deployment Script
# This script uses direct parameter values instead of JSON file

STACK_NAME=${1:-ecs-fargate-demo-stack}
TEMPLATE_FILE="ecs-fargate-stack.yaml"
REGION="us-west-2"

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

echo "🚀 Deploying ECS Fargate Stack..."
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Validate CloudFormation template
echo "🔍 Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://$TEMPLATE_FILE \
    --region $REGION

if [ $? -ne 0 ]; then
    echo "❌ Template validation failed!"
    exit 1
fi

echo "✅ Template validation successful!"
echo ""

# Deploy the stack
echo "📦 Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file $TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        ProjectName=$PROJECT_NAME \
        ResourceSuffix=$RESOURCE_SUFFIX \
        ImageURI=$IMAGE_URI \
        VpcId=$VPC_ID \
        SubnetIds=$SUBNET_IDS \
        DesiredCount=$DESIRED_COUNT \
        ContainerCpu=$CONTAINER_CPU \
        ContainerMemory=$CONTAINER_MEMORY \
        Environment=$ENVIRONMENT \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Stack deployment completed successfully!"
    echo ""
    
    # Get stack outputs
    echo "📋 Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
        
    echo ""
    echo "🌐 Your application should be available at:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
        --output text
else
    echo "❌ Stack deployment failed!"
    exit 1
fi