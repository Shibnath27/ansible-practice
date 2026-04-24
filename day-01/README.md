# Day 01 – Introduction to Ansible and Inventory Setup

## Overview

Today I explored Ansible, an agentless configuration management tool used to automate server configuration, application deployment, and infrastructure management.

I set up a control node, configured multiple EC2 instances as managed nodes, created an inventory, and executed ad-hoc commands to validate connectivity and perform operations.

---

## What is Configuration Management?

Configuration management is the process of maintaining systems in a **desired, consistent state**.

### Why we need it:

* Avoid manual configuration errors
* Ensure consistency across multiple servers
* Enable automation at scale
* Support idempotency (same result every run)
* Reduce configuration drift

---

## Ansible vs Other Tools

| Tool    | Type        | Key Difference              |
| ------- | ----------- | --------------------------- |
| Ansible | Agentless   | Uses SSH, no agent required |
| Puppet  | Agent-based | Requires agent installation |
| Chef    | Agent-based | Uses Ruby DSL               |
| Salt    | Hybrid      | Supports agent + agentless  |

**Key Advantage of Ansible:**
Simple, agentless, easy to start, minimal overhead.

---

## What Does "Agentless" Mean?

Agentless means:

* No software installation required on managed nodes
* Uses SSH for communication
* Executes tasks remotely using Python

### Connection Flow:

Control Node → SSH → Managed Node → Execute Module → Return Output

---

## Ansible Architecture

```
Control Node
   |
   | SSH
   ↓
Managed Nodes (EC2 Instances)

Inventory → Defines hosts
Modules → Perform tasks (yum, copy, command)
Playbooks → Define automation in YAML
```

### Components:

* **Control Node**: Machine where Ansible is installed
* **Managed Nodes**: Target servers (EC2 instances)
* **Inventory**: List of hosts and groups
* **Modules**: Units of work
* **Playbooks**: YAML automation scripts

---

## Lab Setup

### Infrastructure

* 3 EC2 Instances (t2.micro)

  * Web Server
  * App Server
  * DB Server
* OS: Amazon Linux 2
* Security Group: SSH (port 22) enabled
* SSH Key Pair configured

### SSH Verification

```
ssh -i ~/your-key.pem ec2-user@<public-ip>
```

---

## Ansible Installation

Installed Ansible on:
👉 Control Node (local machine / dedicated EC2)

### Commands:

```
sudo apt update
sudo apt install ansible -y
```

### Verification:

```
ansible --version
```

### Why only on Control Node?

Because Ansible is agentless:

* No installation required on managed nodes
* Uses SSH to execute tasks remotely

---

## Inventory Configuration

### File: `inventory.ini`

```
[web]
web-server ansible_host=<PUBLIC_IP_1>

[app]
app-server ansible_host=<PUBLIC_IP_2>

[db]
db-server ansible_host=<PUBLIC_IP_3>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/your-key.pem
```

### Test Connectivity

```
ansible all -i inventory.ini -m ping
```

Expected Output:

```
SUCCESS => "ping": "pong"
```

---

## Ad-Hoc Commands

### Check uptime

```
ansible all -i inventory.ini -m command -a "uptime"
```

### Check memory (web servers)

```
ansible web -i inventory.ini -m command -a "free -h"
```

### Check disk usage

```
ansible all -i inventory.ini -m command -a "df -h"
```

### Install package

```
ansible web -i inventory.ini -m yum -a "name=git state=present" --become
```

### Copy file

```
echo "Hello from Ansible" > hello.txt
ansible all -i inventory.ini -m copy -a "src=hello.txt dest=/tmp/hello.txt"
```

### Verify file

```
ansible all -i inventory.ini -m command -a "cat /tmp/hello.txt"
```

---

## What Does `--become` Do?

`--become` enables **privilege escalation** (like sudo).

### When to use:

* Installing packages
* Modifying system files
* Managing services

Without it → permission denied
With it → runs as root

---

## Inventory Groups and Patterns

### Group of Groups

```
[application:children]
web
app

[all_servers:children]
application
db
```

### Commands:

```
ansible application -i inventory.ini -m ping
ansible db -i inventory.ini -m ping
ansible all_servers -i inventory.ini -m ping
```

### Patterns:

```
ansible 'web:app' -m ping      # OR
ansible 'all:!db' -m ping     # EXCLUDE db
```

---

## Ansible Configuration File

### File: `ansible.cfg`

```
[defaults]
inventory = inventory.ini
host_key_checking = False
remote_user = ec2-user
private_key_file = ~/your-key.pem
```

### Result:

```
ansible all -m ping
```

(No need to specify inventory manually)

---

## Key Learnings

* Ansible is **agentless** and uses SSH
* Inventory defines infrastructure targets
* Ad-hoc commands are useful for quick tasks
* `--become` is required for privileged operations
* Grouping enables scalable automation
* Configuration management ensures consistency and reliability

---

## Next Steps

* Convert ad-hoc commands into **playbooks**
* Integrate Ansible with Terraform
* Automate full application deployment

---
