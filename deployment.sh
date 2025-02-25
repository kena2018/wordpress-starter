#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "parameter missing"
    echo "Usage: $0 <image_name> <aws_access_key_id> <aws_secret_access_key> <aws_region>"
    exit 1
fi

# Set variables from command-line arguments
image_name="$1"
AWS_ACCESS_KEY_ID="$2"
AWS_SECRET_ACCESS_KEY="$3"
AWS_DEFAULT_REGION="$4"

# Export AWS credentials and region
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# Set region variable
region="$AWS_DEFAULT_REGION"



# Get AWS account ID
account_id() {
    echo "Fetching AWS Account ID..."
    aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)
}

# Docker login
docker_login() {
    echo "Logging into Docker..."
    aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "${aws_account_id}".dkr.ecr."$region".amazonaws.com
}

# Build Docker image
build_image() {
    echo "Building Docker image..."
    docker build --no-cache -t "${image_name}" .
}

# Tag Docker image
tag_image() {
    echo "Tagging Docker image..."
    docker tag "${image_name}":latest "${aws_account_id}".dkr.ecr."$region".amazonaws.com/"${image_name}":latest
}

# Push Docker image
push_image() {
    echo "Pushing Docker image to ECR..."
    docker push "${aws_account_id}".dkr.ecr."$region".amazonaws.com/"${image_name}":latest
    push_result=$?
    return "${push_result}"
}

# Main execution

# Get AWS account ID
account_id

# Docker login
docker_login

# Build Docker image
build_image

# Tag Docker image
tag_image

# Push Docker image
push_image
push_result=$?

# Exit with the result of the push command
exit "${push_result}"
