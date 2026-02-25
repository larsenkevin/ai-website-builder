#!/bin/bash
# Configure Lightsail firewall rules after CloudFormation deployment

set -e

STACK_NAME="ai-website-builder"
REGION="us-east-1"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get instance name from CloudFormation stack
print_info "Getting instance name from CloudFormation stack..."
INSTANCE_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceName`].OutputValue' \
    --output text)

if [ -z "$INSTANCE_NAME" ]; then
    print_error "Could not get instance name from stack"
    exit 1
fi

print_info "Instance name: $INSTANCE_NAME"

# Configure firewall rules
print_info "Opening port 80 (HTTP)..."
aws lightsail open-instance-public-ports \
    --instance-name $INSTANCE_NAME \
    --port-info fromPort=80,toPort=80,protocol=tcp \
    --region $REGION

print_info "Opening port 443 (HTTPS)..."
aws lightsail open-instance-public-ports \
    --instance-name $INSTANCE_NAME \
    --port-info fromPort=443,toPort=443,protocol=tcp \
    --region $REGION

print_info "Opening port 41641 (Tailscale UDP)..."
aws lightsail open-instance-public-ports \
    --instance-name $INSTANCE_NAME \
    --port-info fromPort=41641,toPort=41641,protocol=udp \
    --region $REGION

print_info "Firewall configuration complete!"
print_info "Verifying open ports..."

aws lightsail get-instance-port-states \
    --instance-name $INSTANCE_NAME \
    --region $REGION \
    --query 'portStates[*].[fromPort,toPort,protocol,state]' \
    --output table
