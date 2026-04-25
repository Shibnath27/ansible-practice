# Day 02 – Ansible Playbooks and Modules

## Overview

Today I moved from ad-hoc commands to structured automation using Ansible playbooks.
Playbooks define the **desired state** of systems and ensure consistency through idempotent execution.

I implemented multiple playbooks to install packages, manage services, configure files, and handle conditional restarts using handlers.

---

## What is a Playbook?

A playbook is a **YAML-based declarative configuration file** that defines:

* What to do (tasks)
* Where to do it (hosts)
* How to do it (modules)

---

## Task 1 – Install and Configure Nginx

### File: `install-nginx.yml`

```yaml
---
- name: Install and start Nginx on web servers
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Create a custom index page
      copy:
        content: "<h1>Deployed by Ansible - TerraWeek Server</h1>"
        dest: /usr/share/nginx/html/index.html
```

### Execution

```
ansible-playbook -i ../inventory.ini install-nginx.yml
```

### Key Observation – Idempotency

* First run → `changed`
* Second run → `ok`

This confirms Ansible only applies changes when required.

---

## Playbook Structure Explained

```yaml
---
- name: Play name
  hosts: web
  become: true

  tasks:
    - name: Task name
      module_name:
        key: value
```

### Concepts

| Component | Description                          |
| --------- | ------------------------------------ |
| Play      | Targets a group of hosts             |
| Task      | Single unit of work                  |
| Module    | Action executed (yum, copy, service) |

### Answers

**Play vs Task**

* Play = defines *where*
* Task = defines *what*

**Multiple plays?**
Yes. A single playbook can contain multiple plays.

**become: true**

* Play level → applies to all tasks
* Task level → applies only to that task

**Task failure behavior**

* By default, play stops on failure for that host
* Other hosts continue execution

---

## Task 3 – Essential Modules

### File: `essential-modules.yml`

```yaml
---
- name: Practice essential modules
  hosts: all
  become: true

  tasks:

    - name: Install packages
      yum:
        name:
          - git
          - curl
          - wget
          - tree
        state: present

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: true

    - name: Copy config file
      copy:
        src: files/app.conf
        dest: /etc/app.conf
        owner: root
        group: root
        mode: '0644'

    - name: Create application directory
      file:
        path: /opt/myapp
        state: directory
        owner: ec2-user
        mode: '0755'

    - name: Check disk space
      command: df -h
      register: disk_output

    - name: Print disk space
      debug:
        var: disk_output.stdout_lines

    - name: Count running processes
      shell: ps aux | wc -l
      register: process_count

    - name: Show process count
      debug:
        msg: "Total processes: {{ process_count.stdout }}"

    - name: Set timezone
      lineinfile:
        path: /etc/environment
        line: 'TZ=Asia/Kolkata'
        create: true
```

### command vs shell

| Module  | Behavior                   |
| ------- | -------------------------- |
| command | No shell processing (safe) |
| shell   | Supports pipes, redirects  |

**Use command whenever possible**
Use shell only when required.

---

## Task 4 – Handlers

### File: `nginx-config.yml`

```yaml
---
- name: Configure Nginx
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

    - name: Deploy config
      copy:
        src: files/nginx.conf
        dest: /etc/nginx/nginx.conf
      notify: Restart Nginx

    - name: Ensure Nginx running
      service:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

### Key Concept

Handlers run **only when notified**.

### Observation

* First run → handler triggered
* Second run → no restart

This prevents unnecessary service disruption.

---

## Task 5 – Safe Execution

### Dry Run

```
ansible-playbook install-nginx.yml --check
```

### Diff Mode

```
ansible-playbook nginx-config.yml --check --diff
```

### Verbosity

```
-v   basic
-vv  more details
-vvv debug
```

### Host Limiting

```
ansible-playbook install-nginx.yml --limit web-server
```

### Why `--check --diff` is critical

* Prevents accidental changes
* Shows exact modifications
* Safe for production validation
* Enables change review before execution

---

## Task 6 – Multi-Play Playbook

### File: `multi-play.yml`

```yaml
---
- name: Configure web servers
  hosts: web
  become: true
  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

- name: Configure app servers
  hosts: app
  become: true
  tasks:
    - name: Install dependencies
      yum:
        name:
          - gcc
          - make
        state: present

- name: Configure db servers
  hosts: db
  become: true
  tasks:
    - name: Install MySQL client
      yum:
        name: mariadb105
        state: present
```

### Key Insight

Each play targets a different group → clean separation of concerns.

---

## Key Learnings

* Playbooks are declarative and idempotent
* Modules are reusable building blocks
* Handlers optimize service restarts
* `command` is safer than `shell`
* `--check --diff` is essential for production safety
* Multi-play design improves scalability

---