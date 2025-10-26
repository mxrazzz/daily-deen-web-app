# 🌙 Daily Deen Web App

A fully automated deployment of the Daily Deen Islamic dashboard website using **Docker**, **Terraform**, **Ansible**, and **GitHub Actions**.

[![Deploy to AWS](https://github.com/mxrazzz/daily-deen-web-app/actions/workflows/deploy.yml/badge.svg)](https://github.com/mxrazzz/daily-deen-web-app/actions/workflows/deploy.yml)

---

## 📋 Table of Contents

- [What is This Project?](#-what-is-this-project)
- [How It Works](#-how-it-works)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Setup Instructions](#-setup-instructions)
- [Deployment](#-deployment)
- [Workflows Explained](#-workflows-explained)
- [Troubleshooting](#-troubleshooting)
- [What I Learned](#-what-i-learned)

---

## 🎯 What is This Project?

This project automatically deploys a **static Islamic website** (Daily Deen) to AWS using modern DevOps practices. When you push code to GitHub, it automatically:

1. 🏗️ **Creates** an AWS EC2 server (using Terraform)
2. 🐳 **Packages** the website in a Docker container
3. 🚀 **Deploys** it to the cloud (using Ansible)
4. 🌐 Makes it **live on the internet**

All of this happens **automatically** with zero manual intervention!

---

## 🔧 How It Works

Think of it like building a store:

1. **Terraform** = The builder who constructs the physical store (AWS EC2 server)
2. **Docker** = The packaging that wraps your website like a gift box
3. **Ansible** = The interior designer who sets everything up inside the store
4. **GitHub Actions** = The manager who coordinates everyone automatically

```
📝 Push Code to GitHub
    ↓
🤖 GitHub Actions Starts
    ↓
🏗️ Terraform Creates EC2 Server
    ↓
⏳ Wait for Server to Boot
    ↓
🔧 Ansible Installs Docker
    ↓
🐳 Docker Builds Container
    ↓
🚀 Website Goes Live!
    ↓
🌐 http://your-ec2-ip/
```

---

## 🛠️ Tech Stack

| Tool               | Purpose                                        | Version           |
| ------------------ | ---------------------------------------------- | ----------------- |
| **Terraform**      | Infrastructure as Code (creates AWS resources) | >= 1.0            |
| **Ansible**        | Configuration Management (sets up the server)  | 2.19              |
| **Docker**         | Containerization (packages the website)        | 28.5.1            |
| **GitHub Actions** | CI/CD Pipeline (automates everything)          | N/A               |
| **AWS EC2**        | Cloud Server (hosts the website)               | Amazon Linux 2023 |
| **nginx**          | Web Server (serves the HTML)                   | Alpine            |

---

## 📁 Project Structure

```
daily-deen-web-app/
│
├── .github/
│   ├── workflows/
│   │   ├── deploy.yml              # Main deployment workflow (Terraform + Ansible)
│   │   └── deploy-ansible-only.yml # Debug workflow (Ansible only)
│   └── main.yml                     # Legacy workflow (with AWS OIDC)
│
├── index.html                       # Your Daily Deen website (1031 lines)
├── dockerfile                       # Instructions to build Docker container
├── main.tf                          # Terraform configuration (AWS infrastructure)
├── playbook.yml                     # Ansible playbook (server setup)
└── README.md                        # You are here! 📍
```

---

## ✅ Prerequisites

Before you start, you need:

1. **GitHub Account** (free)
2. **AWS Account** (free tier eligible)
3. **Git** installed on your computer
4. **Basic knowledge** of:
   - How to use a terminal/PowerShell
   - What SSH keys are
   - Basic AWS concepts (EC2, Security Groups)

---

## 🚀 Setup Instructions

### Step 1: Clone the Repository

```powershell
git clone https://github.com/mxrazzz/daily-deen-web-app.git
cd daily-deen-web-app
```

### Step 2: Generate SSH Keys

```powershell
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\daily-deen-key" -N '""'

# View the public key (you'll need this later)
Get-Content "$env:USERPROFILE\.ssh\daily-deen-key.pub"

# View the private key (you'll need this too)
Get-Content "$env:USERPROFILE\.ssh\daily-deen-key"
```

### Step 3: Get Your AWS Credentials

1. Log in to AWS Console
2. Go to **IAM** → **Users** → **Create User**
3. Attach policy: `AmazonEC2FullAccess`
4. Create **Access Keys** → Save them somewhere safe!

### Step 4: Create S3 Bucket for Terraform State

```powershell
# Install/Configure AWS CLI first
aws configure

# Create the S3 bucket
aws s3 mb s3://daily-deen-bucket --region us-east-1
```

### Step 5: Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name             | Value                            | Where to Get It                                                 |
| ----------------------- | -------------------------------- | --------------------------------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | Your AWS access key              | From Step 3                                                     |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key              | From Step 3                                                     |
| `SSH_PUBLIC_KEY`        | Contents of `daily-deen-key.pub` | From Step 2                                                     |
| `SSH_PRIVATE_KEY`       | Contents of `daily-deen-key`     | From Step 2                                                     |
| `MY_IP_ADDRESS`         | Your IP (e.g., `149.34.137.245`) | Run: `(Invoke-WebRequest -Uri "https://api.ipify.org").Content` |

---

## 🎬 Deployment

### Automatic Deployment (Recommended)

Just push to the `main` branch:

```powershell
git add .
git commit -m "Update website"
git push origin main
```

GitHub Actions will automatically deploy everything! 🎉

### Manual Deployment

Go to **Actions** tab → **Deploy Daily Deen to AWS** → **Run workflow** → **Run workflow**

### Ansible-Only Deployment (Debugging)

If you already have EC2 infrastructure:

Go to **Actions** tab → **Deploy with Ansible Only** → **Run workflow** → **Run workflow**

---

## 🔍 Workflows Explained

### `deploy.yml` - Full Deployment

**When it runs:** On every push to `main` branch

**What it does:**

1. Checks out your code
2. Logs into AWS
3. Runs Terraform to create/update infrastructure
4. Waits 120 seconds for EC2 to boot
5. Installs Ansible
6. Runs Ansible playbook to deploy website

**Use this when:** You want full automation

---

### `deploy-ansible-only.yml` - Debugging Workflow

**When it runs:** Manual trigger only

**What it does:**

1. Skips Terraform (assumes EC2 already exists)
2. Finds your EC2 instance by tag name
3. Runs Ansible to deploy website

**Use this when:**

- Terraform is causing issues
- You just want to update the website
- Debugging deployment problems

---

## 🐛 Troubleshooting

### Problem: "Duplicate resource" errors

**Solution:** The S3 backend in `main.tf` should prevent this. Make sure you created the S3 bucket!

### Problem: "SSH connection timed out"

**Solution:** Check that your security group allows SSH from `0.0.0.0/0` (GitHub Actions IPs change constantly)

### Problem: "Docker permission denied"

**Solution:** The playbook uses `sudo docker` commands to bypass this. Already fixed! ✅

### Problem: "ami-0453ec754f44f9a4a not found"

**Solution:** This AMI is region-specific (us-east-1). If you change regions, you'll need a different AMI ID.

### Problem: Website not loading

**Solution:**

1. Check security group allows HTTP (port 80) from `0.0.0.0/0`
2. Wait 2-3 minutes after deployment
3. Check GitHub Actions logs for errors

---

## 🎓 What I Learned

Building this project taught me:

- ✅ **Terraform**: How to create cloud infrastructure as code
- ✅ **Ansible**: How to automate server configuration
- ✅ **Docker**: How to containerize applications
- ✅ **GitHub Actions**: How to build CI/CD pipelines
- ✅ **AWS EC2**: How to deploy to the cloud
- ✅ **DevOps**: The power of automation!

### Key Concepts

**Infrastructure as Code (IaC):** Instead of clicking buttons in AWS console, you write code (`main.tf`) that creates resources automatically.

**Configuration Management:** Instead of manually installing Docker and running commands, Ansible does it for you (`playbook.yml`).

**Containerization:** Instead of installing software directly on the server, you package it in a container that works anywhere.

**CI/CD:** Instead of manually deploying after every change, GitHub Actions does it automatically when you push code.

---

## 🔗 Useful Commands

```powershell
# Check AWS credentials
aws sts get-caller-identity

# List running EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=Daily Deen Web Server" --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" --output table

# SSH into your EC2 instance
ssh -i "$env:USERPROFILE\.ssh\daily-deen-key" ec2-user@YOUR_EC2_IP

# Check if Docker container is running (on EC2)
sudo docker ps

# View container logs (on EC2)
sudo docker logs daily-deen-web
```

---

## 📝 License

This project is open source and available for learning purposes.

---

## 🙏 Acknowledgments

Built with patience, coffee, and lots of debugging! ☕

Special thanks to the open-source community for amazing tools like Terraform, Ansible, and Docker.

---

## 📧 Contact

If you have questions, feel free to open an issue on GitHub!

---

**Made with ❤️ by Meraz**
