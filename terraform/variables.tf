variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "postgres-docker-lab"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"

  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Instance type must be from the t3 family for cost efficiency."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 20 and 100 GB."
  }
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access (must already exist in your AWS account)"
  type        = string
}

variable "db_user" {
  description = "PostgreSQL database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL database password (minimum 12 characters)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}

variable "db_name" {
  description = "Default database name"
  type        = string
  default     = "myapp_db"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access (use your IP/32)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Change this to your IP address in production!
}

variable "allowed_postgres_cidr" {
  description = "CIDR blocks allowed for PostgreSQL access"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allowed_pgadmin_cidr" {
  description = "CIDR blocks allowed for PgAdmin web access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this in production!
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Portfolio   = "Systems Engineer"
  }
}
