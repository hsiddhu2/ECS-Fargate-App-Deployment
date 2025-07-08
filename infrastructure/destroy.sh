#!/bin/bash

# ECS Fargate CloudFormation Stack Destruction Script
# Usage: ./destroy.sh [stack-name]

STACK_NAME=${1:-ecs-fargate-demo-stack}
REGION="us-west-2"

echo "🗑️  Destroying ECS Fargate Stack..."
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Check if stack exists
echo "🔍 Checking if stack exists..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Stack '$STACK_NAME' does not exist or is already deleted!"
    exit 1
fi

echo "✅ Stack found!"
echo ""

# Show stack resources before deletion
echo "📋 Resources that will be deleted:"
aws cloudformation list-stack-resources \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'StackResourceSummaries[*].[ResourceType,LogicalResourceId,PhysicalResourceId]' \
    --output table

echo ""
echo "⚠️  WARNING: This will permanently delete all resources in the stack!"
echo "This includes:"
echo "  - ECS Cluster and Service"
echo "  - Application Load Balancer"
echo "  - Security Groups"
echo "  - Target Groups"
echo "  - IAM Roles"
echo "  - CloudWatch Log Groups"
echo ""

# Confirmation prompt
read -p "Are you sure you want to delete the stack? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "❌ Stack deletion cancelled!"
    exit 0
fi

echo ""
echo "🚀 Starting stack deletion..."

# Delete the stack
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Stack deletion initiated successfully!"
    echo ""
    echo "⏳ Waiting for stack deletion to complete..."
    echo "This may take several minutes..."
    
    # Wait for stack deletion to complete
    aws cloudformation wait stack-delete-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Stack deletion completed successfully!"
        echo ""
        echo "📝 Note: ECR repository (if not empty) must be deleted manually:"
        echo "   1. Go to ECR console"
        echo "   2. Select 'ecs-fargate-demo' repository"
        echo "   3. Delete all images first"
        echo "   4. Delete the repository"
    else
        echo ""
        echo "⚠️  Stack deletion may have encountered issues."
        echo "Check the CloudFormation console for details:"
        echo "https://console.aws.amazon.com/cloudformation/home?region=$REGION"
    fi
else
    echo "❌ Failed to initiate stack deletion!"
    echo "Please check your AWS credentials and permissions."
    exit 1
fi