#!/bin/bash
# CloudFormation deployment script for AI Website Builder

set -e

STACK_NAME="ai-website-builder"
TEMPLATE_FILE="lightsail-stack.yaml"
PARAMETERS_FILE="parameters.json"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    if [ ! -f "$PARAMETERS_FILE" ]; then
        print_error "parameters.json not found. Copy parameters.json.example and fill in your values"
        exit 1
    fi
}

# Validate template
validate_template() {
    print_info "Validating CloudFormation template..."
    aws cloudformation validate-template \
        --template-body file://$TEMPLATE_FILE \
        --region $REGION
}

# Create stack
create_stack() {
    print_info "Creating CloudFormation stack..."
    
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --parameters file://$PARAMETERS_FILE \
        --region $REGION
    
    print_info "Stack creation initiated. Waiting for completion..."
    
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    print_info "Stack created successfully!"
    show_outputs
}

# Update stack
update_stack() {
    print_info "Updating CloudFormation stack..."
    
    aws cloudformation update-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --parameters file://$PARAMETERS_FILE \
        --region $REGION
    
    print_info "Stack update initiated. Waiting for completion..."
    
    aws cloudformation wait stack-update-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    print_info "Stack updated successfully!"
    show_outputs
}

# Delete stack
delete_stack() {
    print_warning "This will delete the stack and all resources!"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Delete cancelled"
        exit 0
    fi
    
    print_info "Deleting CloudFormation stack..."
    
    aws cloudformation delete-stack \
        --stack-name $STACK_NAME \
        --region $REGION
    
    print_info "Stack deletion initiated. Waiting for completion..."
    
    aws cloudformation wait stack-delete-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    print_info "Stack deleted successfully!"
}

# Show stack outputs
show_outputs() {
    print_info "Stack outputs:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
}

# Show stack status
show_status() {
    print_info "Stack status:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].[StackName,StackStatus]' \
        --output table
}

# Main script
main() {
    case "${1:-}" in
        create)
            check_prerequisites
            validate_template
            create_stack
            ;;
        update)
            check_prerequisites
            validate_template
            update_stack
            ;;
        delete)
            delete_stack
            ;;
        outputs)
            show_outputs
            ;;
        status)
            show_status
            ;;
        validate)
            validate_template
            ;;
        *)
            echo "AI Website Builder - CloudFormation Deployment Script"
            echo ""
            echo "Usage: $0 {create|update|delete|outputs|status|validate}"
            echo ""
            echo "Commands:"
            echo "  create    - Create new stack"
            echo "  update    - Update existing stack"
            echo "  delete    - Delete stack"
            echo "  outputs   - Show stack outputs"
            echo "  status    - Show stack status"
            echo "  validate  - Validate template"
            exit 1
            ;;
    esac
}

main "$@"
