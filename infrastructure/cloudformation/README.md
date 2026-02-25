# CloudFormation Deployment

This directory contains AWS CloudFormation templates for deploying the AI Website Builder on AWS Lightsail.

## Prerequisites

1. **AWS CLI**: Install and configure AWS CLI
   ```bash
   aws configure
   ```

2. **Required Information**:
   - Domain name for your website
   - Email address for SSL certificates
   - Anthropic API key
   - Tailscale auth key

## Deployment Steps

### 1. Configure Parameters

Copy the example parameters file:

```bash
cp parameters.json.example parameters.json
```

Edit `parameters.json` with your actual values:

```json
[
  {
    "ParameterKey": "InstanceName",
    "ParameterValue": "ai-website-builder"
  },
  {
    "ParameterKey": "Domain",
    "ParameterValue": "yourdomain.com"
  },
  {
    "ParameterKey": "SSLEmail",
    "ParameterValue": "admin@yourdomain.com"
  },
  {
    "ParameterKey": "AnthropicAPIKey",
    "ParameterValue": "sk-ant-your-actual-key"
  },
  {
    "ParameterKey": "TailscaleAuthKey",
    "ParameterValue": "tskey-auth-your-actual-key"
  }
]
```

### 2. Validate Template

```bash
aws cloudformation validate-template \
  --template-body file://lightsail-stack.yaml
```

### 3. Create Stack

```bash
aws cloudformation create-stack \
  --stack-name ai-website-builder \
  --template-body file://lightsail-stack.yaml \
  --parameters file://parameters.json \
  --region us-east-1
```

### 4. Monitor Stack Creation

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1
```

Or watch the events:

```bash
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --region us-east-1
```

### 5. Get Stack Outputs

Once the stack is created (status: CREATE_COMPLETE):

```bash
aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'Stacks[0].Outputs'
```

## Updating the Stack

To update the infrastructure:

```bash
aws cloudformation update-stack \
  --stack-name ai-website-builder \
  --template-body file://lightsail-stack.yaml \
  --parameters file://parameters.json \
  --region us-east-1
```

## Deleting the Stack

To remove all resources:

```bash
aws cloudformation delete-stack \
  --stack-name ai-website-builder \
  --region us-east-1
```

**Warning**: This will delete the instance and all data.

## Deployment Script

A convenience script is provided for common operations:

```bash
# Deploy stack
./deploy-cloudformation.sh create

# Update stack
./deploy-cloudformation.sh update

# Delete stack
./deploy-cloudformation.sh delete

# Show outputs
./deploy-cloudformation.sh outputs
```

## Resources Created

- **Lightsail Instance**: Ubuntu 22.04 LTS, nano_2_0 bundle (1 CPU, 1GB RAM)
- **Static IP**: Persistent IP address for the instance
- **Static IP Attachment**: Associates the IP with the instance

## Firewall Configuration

Note: CloudFormation for Lightsail has limited support for port configuration. After stack creation, you need to manually configure the firewall rules:

```bash
# Get the instance name from outputs
INSTANCE_NAME=$(aws cloudformation describe-stacks \
  --stack-name ai-website-builder \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceName`].OutputValue' \
  --output text)

# Open required ports
aws lightsail open-instance-public-ports \
  --instance-name $INSTANCE_NAME \
  --port-info fromPort=80,toPort=80,protocol=tcp

aws lightsail open-instance-public-ports \
  --instance-name $INSTANCE_NAME \
  --port-info fromPort=443,toPort=443,protocol=tcp

aws lightsail open-instance-public-ports \
  --instance-name $INSTANCE_NAME \
  --port-info fromPort=41641,toPort=41641,protocol=udp
```

Or use the provided script:

```bash
./configure-firewall.sh
```

## Cost Estimate

- **Lightsail Instance (nano_2_0)**: $7/month
- **Static IP**: Free (while attached)
- **Data Transfer**: 1TB included
- **Total**: ~$7/month

## Troubleshooting

### Stack Creation Failed

Check the stack events for error details:

```bash
aws cloudformation describe-stack-events \
  --stack-name ai-website-builder \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### Cannot SSH to Instance

1. Verify the instance is running
2. Check security group rules
3. Ensure you're using the correct SSH key

### User Data Script Issues

SSH into the instance and check logs:

```bash
ssh ubuntu@<public-ip>
sudo cat /var/log/user-data.log
```

## Next Steps

After CloudFormation deployment:

1. Configure firewall rules (see above)
2. Complete NGINX configuration (Task 1.2)
   ```bash
   scp infrastructure/scripts/configure-nginx.sh ubuntu@<server-ip>:~/
   ssh ubuntu@<server-ip>
   sudo ./configure-nginx.sh
   ```
   See `infrastructure/scripts/README.md` for details.
3. Set up Tailscale VPN (Task 1.4)
4. Set up Let's Encrypt SSL (Task 1.5)
5. Create systemd services (Task 1.6)
