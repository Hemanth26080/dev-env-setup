# Local Development Environment Setup (Red Hat Based)

## 📌 Overview

This project provides a **production-ready Bash script** that automatically sets up a **local development environment** on **Red Hat–based Linux systems** (RHEL, CentOS Stream, Rocky Linux, AlmaLinux).

With **one command**, the script:
- Installs required development tools
- Configures Docker correctly
- Sets environment variables
- Clones project repositories
- Creates a test database
- Logs everything safely

👉 This eliminates manual setup, saves hours, and ensures **consistent environments for all developers**.

---

## 🎯 Why This Project Exists (Simple Explanation)

Imagine a new developer joins the team.

Instead of:
- Installing tools one by one
- Forgetting steps
- Using wrong versions

They run **one script**, and everything is ready.

This is exactly how **real DevOps teams onboard developers**.

---

## 🧠 Real-World DevOps Use Cases

- Developer onboarding
- Standardized local environments
- CI/CD build agents preparation
- Cloud VM bootstrap scripts
- DevSecOps baseline setup

This pattern is used in **real companies**, not tutorials.

---

## 🖥️ Supported Operating Systems

✅ Supported:
- Red Hat Enterprise Linux (RHEL)
- CentOS Stream
- Rocky Linux
- AlmaLinux

❌ Not supported:
- Ubuntu / Debian
- macOS
- Windows

(The script safely exits if run on unsupported systems.)

---

## 📁 Project Structure

dev-env-setup/
├── setup-dev.sh
├── README.md


---

## ⚙️ What the Script Does (Step by Step)

1. **Safety checks**
   - Prevents running as root
   - Confirms Red Hat–based OS
   - Uses strict error handling

2. **Logging**
   - Creates timestamped log files
   - Saves logs in `~/logs/`
   - Logs both stdout and stderr

3. **System preparation**
   - Enables EPEL repository
   - Updates system packages
   - Configures Docker repository

4. **Tool installation & validation**
   - Git
   - Curl
   - Docker CE
   - SQLite
   - Verifies each installation

5. **Docker setup**
   - Enables Docker service
   - Adds user to docker group safely

6. **Environment configuration**
   - Creates `~/.dev_env`
   - Adds development environment variables

7. **Project setup**
   - Clones required Git repositories
   - Creates a test SQLite database

---

## 🚀 How to Use

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/dev-env-setup.git
cd dev-env-setup
