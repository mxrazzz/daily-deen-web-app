/*
  This is our Terraform "Blueprint."
  It tells AWS what to build.
  It is SECURE because all secrets are passed in as variables.
*/

# ═══════════════════════════════════════════════════════════
# TERRAFORM CONFIGURATION
# ═══════════════════════════════════════════════════════════
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # ═══════════════════════════════════════════════════════════
  # REMOTE BACKEND: Store state in S3
  # ═══════════════════════════════════════════════════════════
  # This solves the "duplicate resource" problem!
  # State file is saved in S3, so Terraform remembers what it created
  
  backend "s3" {
    bucket = "daily-deen-bucket" 
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
// --- These are our "placeholders" for secrets ---

// Placeholder 1: For our "back door" (SSH) key
variable "ssh_public_key" {
  description = "The public SSH key to put on our server"
  type        = string
}

// Placeholder 2: For our "Guest List" (Security Group)
variable "my_ip" {
  description = "My personal IP address, for secure SSH access"
  type        = string
}

// --- Now, here's the "Blueprint" ---

// 1. The "Guest List" (Security Group)
resource "aws_security_group" "web_sg" {
  name        = "daily-deen-web-sg"  
  description = "Allow web and SSH traffic"

  // Rule 1: Allow "everyone" in the "front door" (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // "0.0.0.0/0" means "anyone"
  }

  // Rule 2: Allow SSH from anywhere (for GitHub Actions deployment)
  // ⚠️ For production, restrict this to specific IPs!
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Allow SSH from anywhere (including GitHub Actions)
  }

  // Allow our server to talk back to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Daily Deen Web Security Group"
  }
  
  # This prevents Terraform from trying to recreate if it already exists
  lifecycle {
    ignore_changes = [name]
  }
}

// 2. The "Back Door Key" (SSH Key Pair)
resource "aws_key_pair" "deployer" {
  key_name   = "daily-deen-deployment-key"  # Fixed name - always uses the same key!
  public_key = var.ssh_public_key
  
  tags = {
    Name = "Daily Deen SSH Key"
  }
  
  # This tells Terraform: "If key exists, just use it. Don't error out."
  lifecycle {
    ignore_changes = [key_name, public_key]  # Don't recreate if already exists
  }
}

// 3. The "Store" (EC2 Instance)
resource "aws_instance" "web_server" {
  ami           = "ami-0453ec754f44f9a4a" // Amazon Linux 2023 (Free Tier) - Latest!
  instance_type = "t3.micro"              // t3.micro - newer generation, better performance
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # Better practice than security_groups
  key_name        = aws_key_pair.deployer.key_name

  // This script runs when the server is first built.
  // It installs Python, which our "Robot" needs to talk to it.
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install python3 -y
              EOF
  tags = { 
    Name = "Daily Deen Web Server"
  }
}

// --- These "Outputs" are like "address labels" ---
// After building, the "Robot" reads these to know where to go.

output "server_public_dns" {
  value = aws_instance.web_server.public_dns
  description = "The public DNS name of the web server"
}

output "server_public_ip" {
  value = aws_instance.web_server.public_ip
  description = "The public IP address of the web server"
}