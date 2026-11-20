# Terraform AWS Deployment

This directory contains Infrastructure as Code (IaC) for deploying the PostgreSQL Docker lab to AWS EC2.

## Quick Start

### 1. Prerequisites
- Terraform 1.0+
- AWS Account with EC2, VPC, and IAM permissions
- AWS CLI configured with credentials
- SSH key pair created in your target AWS region

### 2. Create SSH Key Pair
```bash
# Create key pair in AWS (if you don't have one)
aws ec2 create-key-pair \
    --key-name postgres-lab-key \
    --region us-east-1 \
    --query 'KeyMaterial' \
    --output text > postgres-lab-key.pem

chmod 400 postgres-lab-key.pem
```

### 3. Configure Variables
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
nano terraform.tfvars

# Key things to change:
# - key_pair_name: Set to your actual key pair name
# - db_password: Change to a secure password
# - allowed_ssh_cidr: Restrict to YOUR_IP/32 (get from: curl https://checkip.amazonaws.com)
```

### 4. Deploy
```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy the infrastructure
terraform apply

# Save the outputs (they're important!)
terraform output > deployment-info.txt
```

### 5. Connect
```bash
# SSH into your instance
ssh -i postgres-lab-key.pem ubuntu@$(terraform output -raw instance_public_ip)

# Verify containers are running
docker ps

# View PostgreSQL logs
docker-compose logs postgres

# Wait for initialization
sleep 30

# Test connection
docker-compose exec postgres psql -U postgres -c "SELECT version();"
```

## File Descriptions

- **main.tf**: Core AWS resources (VPC, EC2, Security Groups, networking)
- **variables.tf**: Input variables with validation and defaults
- **outputs.tf**: Output values (IP addresses, URLs, connection strings)
- **terraform.tfvars.example**: Example of variable values (copy to terraform.tfvars)
- **user_data.sh**: EC2 initialization script (installs Docker, starts services)

## Architecture

```
┌─ VPC (10.0.0.0/16)
│
├─ Public Subnet (10.0.1.0/24)
│  │
│  └─ EC2 Instance (Ubuntu 22.04)
│     ├─ Docker Engine
│     ├─ Docker Compose
│     └─ PostgreSQL & PgAdmin containers
│
├─ Security Group
│  ├─ SSH (22): Restricted by CIDR
│  ├─ PostgreSQL (5432): VPC internal
│  └─ PgAdmin (5050): Public (restrict in production!)
│
├─ Elastic IP
│  └─ Attached to EC2 instance
│
└─ Internet Gateway
   └─ Routes public traffic
```

## Cost Estimation

Approximate monthly costs (us-east-1, on-demand):
- **t3.small**: ~$10-15/month
- **t3.micro**: ~$5-8/month
- **Data transfer**: ~$1-5/month
- **EBS storage (20GB gp3)**: ~$2/month

**Total**: ~$15-25/month for t3.small

## Production Considerations

Before going production:

1. **Security**
   - Restrict SSH to your IP (use /32 CIDR)
   - Use AWS Secrets Manager for credentials
   - Enable encryption for EBS volumes
   - Consider using RDS instead of self-managed containers

2. **Availability**
   - Deploy across multiple AZs
   - Set up automated backups
   - Use RDS for managed database
   - Implement load balancing

3. **Monitoring**
   - Enable CloudWatch monitoring
   - Set up CloudWatch alarms
   - Configure log aggregation
   - Implement health checks

4. **Networking**
   - Use private subnets for databases
   - Implement VPN or bastion hosts
   - Restrict security groups to minimum required access
   - Use VPC endpoints for AWS services

## Useful Commands

```bash
# See what will change
terraform plan

# Apply with auto-approval (use with caution!)
terraform apply -auto-approve

# Destroy all resources
terraform destroy

# Destroy specific resource
terraform destroy -target=aws_instance.postgres_server

# Show current state
terraform show

# Format code nicely
terraform fmt -recursive

# Validate syntax
terraform validate

# Get specific output
terraform output instance_public_ip

# Get all outputs
terraform output -json
```

## Troubleshooting

### "EC2 key does not exist"
```bash
# List available keys
aws ec2 describe-key-pairs --region us-east-1

# Create if missing
aws ec2 create-key-pair --key-name postgres-lab-key --region us-east-1 \
  --query 'KeyMaterial' --output text > postgres-lab-key.pem
```

### "Security group not found"
```bash
# Rerun init and apply
terraform init
terraform apply
```

### "Timeout waiting for instance"
```bash
# Check instance logs
aws ec2 get-console-output --instance-id <id> --region us-east-1

# SSH and check user-data logs
tail -100 /var/log/cloud-init-output.log
```

### Can't SSH to instance
```bash
# Check key permissions (must be 400)
ls -la postgres-lab-key.pem

# Verify security group allows port 22
aws ec2 describe-security-groups --group-ids <sg-id> --region us-east-1
```

## State Management

Terraform state is stored in `terraform.tfstate` and `.terraform/`:
- **Never commit to version control**
- **Back up regularly** (contains sensitive information)
- **For teams**: Use remote state (S3 + DynamoDB)

To use remote state:
```bash
# Create S3 bucket for state
aws s3 mb s3://my-terraform-state-bucket

# Add backend configuration
cat >> backend.tf <<EOF
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "postgres-lab/terraform.tfstate"
    region = "us-east-1"
  }
}
EOF

# Migrate state
terraform init
```

## Cleanup

```bash
# Destroy all resources (careful!)
terraform destroy

# Confirm by typing 'yes'

# Check if any resources remain
aws ec2 describe-instances --region us-east-1
aws ec2 describe-volumes --region us-east-1
aws ec2 describe-security-groups --region us-east-1
```

## References

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform Best Practices](https://www.terraform.io/cloud-docs/recommended-practices)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
