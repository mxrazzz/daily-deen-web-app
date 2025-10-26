/*
  This is our Terraform "Blueprint."
  It tells AWS what to build.
  It is SECURE because all secrets are passed in as variables.
*/

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
  name        = "web-sg"
  description = "Allow web and SSH traffic"

  // Rule 1: Allow "everyone" in the "front door" (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // "0.0.0.0/0" means "anyone"
  }

  // Rule 2: Allow *only me* in the "back door" (SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    // This USES our secret IP address from the "Key Safe"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  // Allow our server to talk back to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// 2. The "Back Door Key" (SSH Key Pair)
resource "aws_key_pair" "deployer" {
  key_name   = "my-project-key"
  // This USES our secret public key from the "Key Safe"
  public_key = var.ssh_public_key
}

// 3. The "Store" (EC2 Instance)
resource "aws_instance" "web_server" {
  ami           = "ami-0cff7528ff583bf9a" // Amazon Linux 2 (Free Tier)
  instance_type = "t2.micro"              // Free Tier
  security_groups = [aws_security_group.web_sg.name]
  key_name        = aws_key_pair.deployer.key_name

  // This script runs when the server is first built.
  // It installs Python, which our "Robot" needs to talk to it.
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install python3 -y
              EOF
  tags = { Name = "My Project Web Server" }
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