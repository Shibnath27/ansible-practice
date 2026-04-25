# Day 03 – Variables, Facts, Conditionals and Loops

## Overview

Today I enhanced my Ansible playbooks by introducing **dynamic behavior** using variables, facts, conditionals, and loops.

Instead of static automation, playbooks now adapt based on:

* Host groups
* Environment
* System properties (facts)

---

## Task 1 – Variables in Playbooks

### File: `variables-demo.yml`

```yaml
---
- name: Variable demo
  hosts: all
  become: true

  vars:
    app_name: terraweek-app
    app_port: 8080
    app_dir: "/opt/{{ app_name }}"
    packages:
      - git
      - curl
      - wget

  tasks:
    - name: Print app details
      debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }} to {{ app_dir }}"

    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        mode: '0755'

    - name: Install required packages
      yum:
        name: "{{ packages }}"
        state: present
```

### CLI Override

```
ansible-playbook variables-demo.yml -e "app_name=my-custom-app app_port=9090 app_dir=app packages=docker" -i ../inventory.ini --become

```

### Observation

CLI variables override playbook-defined variables.

---

## Task 2 – group_vars and host_vars

### Directory Structure

```
day-03/
├── inventory.ini
├── ansible.cfg
├── group_vars/
│   ├── all.yml
│   ├── web.yml
│   └── db.yml
├── host_vars/
│   └── web-server.yml
└── playbooks/
    └── site.yml
```

### Variable Files

#### group_vars/all.yml

```yaml
---
ntp_server: pool.ntp.org
app_env: development
common_packages:
  - vim
  - htop
  - tree
```

#### group_vars/web.yml

```yaml
---
http_port: 80
max_connections: 1000
web_packages:
  - nginx
```

#### group_vars/db.yml

```yaml
---
db_port: 3306
db_packages:
  - mysql-server
```

#### host_vars/web-server.yml

```yaml
---
max_connections: 2000
custom_message: "This is the primary web server"
```

### Playbook: `site.yml`

```yaml
---
- name: Apply common config
  hosts: all
  become: true

  tasks:
    - name: Install common packages
      yum:
        name: "{{ common_packages }}"
        state: present

    - name: Show environment
      debug:
        msg: "Environment: {{ app_env }}"

- name: Configure web servers
  hosts: web
  become: true

  tasks:
    - name: Show web config
      debug:
        msg: "HTTP port: {{ http_port }}, Max connections: {{ max_connections }}"

    - name: Show host-specific message
      debug:
        msg: "{{ custom_message }}"
```

### Variable Precedence

Highest → Lowest:

```
-e (CLI vars)
host_vars
group_vars
playbook vars
defaults
```

---

## Task 3 – Ansible Facts

Facts are automatically gathered system data.

### Example Playbook: `facts-demo.yml`

```yaml
---
- name: Facts demo
  hosts: all

  tasks:
    - name: Show system info
      debug:
        msg: >
          Hostname: {{ ansible_hostname }},
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }},
          RAM: {{ ansible_memtotal_mb }}MB,
          IP: {{ ansible_default_ipv4.address }}

    - name: Show interfaces
      debug:
        var: ansible_interfaces
```

### Useful Facts

| Fact                         | Use Case               |
| ---------------------------- | ---------------------- |
| ansible_distribution         | OS-specific logic      |
| ansible_memtotal_mb          | Capacity checks        |
| ansible_default_ipv4.address | Networking             |
| ansible_hostname             | Logging/identification |
| ansible_processor_cores      | Scaling decisions      |

---

## Task 4 – Conditionals

### File: `conditional-demo.yml`

```yaml
---
- name: Conditional tasks demo
  hosts: all
  become: true

  tasks:
    - name: Install Nginx (web only)
      yum:
        name: nginx
        state: present
      when: "'web' in group_names"

    - name: Install MySQL (db only)
      yum:
        name: mysql-server
        state: present
      when: "'db' in group_names"

    - name: Low memory warning
      debug:
        msg: "WARNING: Less than 1GB RAM"
      when: ansible_memtotal_mb < 1024

    - name: Amazon Linux check
      debug:
        msg: "Amazon Linux system"
      when: ansible_distribution == "Amazon"

    - name: Production check
      debug:
        msg: "Production settings applied"
      when: app_env == "production"
```

### Insight

Tasks are skipped automatically if conditions are not met.

---

## Task 5 – Loops

### File: `loops-demo.yml`

```yaml
---
- name: Loops demo
  hosts: all
  become: true

  vars:
    users:
      - name: deploy
        groups: wheel
      - name: monitor
        groups: wheel
      - name: appuser
        groups: users

    directories:
      - /opt/app/logs
      - /opt/app/config
      - /opt/app/data
      - /opt/app/tmp

  tasks:
    - name: Create users
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
        state: present
      loop: "{{ users }}"

    - name: Create directories
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop: "{{ directories }}"

    - name: Install packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - curl
        - unzip
        - jq
```

### loop vs with_items

| Feature        | loop     | with_items |
| -------------- | -------- | ---------- |
| Status         | Modern   | Deprecated |
| Syntax         | Cleaner  | Older      |
| Recommendation | Use loop | Avoid      |

---

## Task 6 – Server Health Report

### File: `server-report.yml`

```yaml
---
- name: Server Health Report
  hosts: all

  tasks:
    - name: Check disk
      command: df -h /
      register: disk_result

    - name: Check memory
      command: free -m
      register: memory_result

    - name: Running services
      shell: systemctl list-units --type=service --state=running | head -20
      register: services_result

    - name: Generate report
      debug:
        msg:
          - "===== {{ inventory_hostname }} ====="
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "IP: {{ ansible_default_ipv4.address }}"
          - "RAM: {{ ansible_memtotal_mb }}MB"
          - "Disk: {{ disk_result.stdout_lines[1] }}"

    - name: Disk alert
      debug:
        msg: "ALERT: Disk usage critical"
      when: "'9[0-9]%' in disk_result.stdout or '100%' in disk_result.stdout"

    - name: Save report
      copy:
        content: |
          Server: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IP: {{ ansible_default_ipv4.address }}
          RAM: {{ ansible_memtotal_mb }}MB
          Disk: {{ disk_result.stdout }}
          Checked at: {{ ansible_date_time.iso8601 }}
        dest: "/tmp/server-report-{{ inventory_hostname }}.txt"
      become: true
```

---

## Key Learnings

* Variables enable dynamic configuration
* group_vars and host_vars separate logic from code
* Facts provide real-time system intelligence
* Conditionals control execution flow
* Loops enable scalable operations
* Register captures command output for reuse

---

## Critical Insight

Static playbooks → **basic automation**
Dynamic playbooks → **real infrastructure management**

---


