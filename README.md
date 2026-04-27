# 🚀 Ansible Practice Repository 

## 📌 Overview

This repository documents my hands-on journey learning **Ansible for configuration management and automation**.

Over 4 days, I progressed from:

* Basic setup and inventory
  ➡️ to playbooks
  ➡️ to dynamic automation (variables, loops)
  ➡️ to production-grade structure (roles, templates, vault)

---

## 🧱 Tech Stack

* Ansible
* AWS EC2
* Linux (Amazon Linux / Ubuntu)
* SSH

---

## 🏗️ Architecture

```
Control Node (Ansible)
        |
        | SSH
        ↓
Managed Nodes (EC2)
  ├── Web Server
  ├── App Server
  └── DB Server
```

---
# Flow-Diagram

<img width="1536" height="1024" alt="ChatGPT Image Apr 27, 2026, 12_23_34 PM" src="https://github.com/user-attachments/assets/20e52b02-c903-464d-ba6f-cd2c8ff2c6f3" />


---
# 📅 Day-wise Breakdown

---

## 📘 Day 01 – Ansible Introduction & Inventory

### 🔹 What I Did

* Installed Ansible on control node
* Created inventory file with grouped hosts
* Connected to EC2 instances using SSH
* Executed ad-hoc commands

### 🔹 Key Concepts

* Agentless architecture (SSH-based)
* Inventory (host grouping)
* Ad-hoc commands
* Privilege escalation (`--become`)

### 🔹 Sample Commands

```bash
ansible all -m ping
ansible web -m command -a "uptime"
ansible all -m copy -a "src=hello.txt dest=/tmp/hello.txt"
```

---

## 📘 Day 02 – Playbooks & Modules

### 🔹 What I Did

* Created playbooks to automate server setup
* Installed and configured Nginx
* Learned essential modules
* Implemented handlers

### 🔹 Key Concepts

* Play vs Task vs Module
* Idempotency
* Handlers (event-driven execution)
* Declarative automation

### 🔹 Example Playbook

```yaml
- name: Install Nginx
  hosts: web
  become: true

  tasks:
    - name: Install package
      yum:
        name: nginx
        state: present
```

---

## 📘 Day 03 – Variables, Facts, Conditionals & Loops

### 🔹 What I Did

* Used variables from multiple sources
* Implemented `group_vars` and `host_vars`
* Used Ansible facts for dynamic decisions
* Applied conditionals (`when`)
* Automated repetitive tasks using loops

### 🔹 Key Concepts

* Variable precedence
* Facts (system information)
* Conditional execution
* Loop-based automation

### 🔹 Example

```yaml
- name: Install Nginx only on web
  yum:
    name: nginx
    state: present
  when: "'web' in group_names"
```

---

## 📘 Day 04 – Roles, Templates, Galaxy & Vault

### 🔹 What I Did

* Converted playbooks into reusable roles
* Created Jinja2 templates for configs
* Installed roles from Ansible Galaxy
* Secured secrets using Ansible Vault

### 🔹 Key Concepts

* Role-based architecture
* Jinja2 templating
* Reusable automation
* Secret management

### 🔹 Role Structure

```
roles/
  webserver/
    tasks/
    handlers/
    templates/
    defaults/
```

### 🔹 Vault Usage

```bash
ansible-vault create group_vars/db/vault.yml
ansible-playbook site.yml --vault-password-file .vault_pass
```

---

# 📂 Repository Structure

```
ansible-practice/
├───day-01
├───day-02
│   └───playbooks
├───day-03
│   ├───group_vars
│   ├───host_vars
│   └───playbooks
├───day-04
│   ├───group_vars
│   │   └───db
│   ├───playbooks
│   │   └───roles
│   │       ├───geerlingguy.docker
│   │       │   ├───.github
│   │       │   │   └───workflows
│   │       │   ├───defaults
│   │       │   ├───handlers
│   │       │   ├───meta
│   │       │   ├───molecule
│   │       │   │   └───default
│   │       │   ├───tasks
│   │       │   └───vars
│   │       ├───geerlingguy.ntp
│   │       │   ├───.github
│   │       │   │   └───workflows
│   │       │   ├───defaults
│   │       │   ├───handlers
│   │       │   ├───meta
│   │       │   ├───molecule
│   │       │   │   └───default
│   │       │   ├───tasks
│   │       │   ├───templates
│   │       │   └───vars
│   │       └───webserver
│   │           ├───defaults
│   │           ├───handlers
│   │           ├───meta
│   │           ├───tasks
│   │           ├───templates
│   │           ├───tests
│   │           └───vars
│   └───templates
├───terraform
│   └───templates
│             └───vars
│   
└───README.md
```

---

# 🎯 Key Learnings

* Ansible is **agentless and SSH-based**
* Playbooks are **idempotent and declarative**
* Variables + facts enable **dynamic automation**
* Roles provide **scalable architecture**
* Vault ensures **secure secret management**

---

# 🚀 Next Steps

* Dynamic Inventory (AWS plugin)
* CI/CD integration (GitHub Actions)
* Terraform + Ansible workflow
* Multi-environment setup (dev/stage/prod)

---

# 📌 Conclusion

This project demonstrates my progression from:
➡️ Basic Ansible usage
➡️ To structured automation
➡️ To production-ready configuration management

---
