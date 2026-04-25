# Day 04 – Roles, Templates, Galaxy and Vault

## Overview

Today I structured my Ansible automation using **roles**, implemented **Jinja2 templates** for dynamic configuration, leveraged **Ansible Galaxy** for reusable components, and secured sensitive data using **Ansible Vault**.

This marks the transition from flat playbooks to **modular, reusable, production-ready automation**.

---

## Task 1 – Jinja2 Templates

### Template: `templates/nginx-vhost.conf.j2`

```jinja2
# Managed by Ansible -- do not edit manually
server {
    listen {{ http_port | default(80) }};
    server_name {{ ansible_hostname }};

    root /var/www/{{ app_name }};
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/{{ app_name }}_access.log;
    error_log /var/log/nginx/{{ app_name }}_error.log;
}
```

### Playbook: `template-demo.yml`

```yaml
---
- name: Deploy Nginx with template
  hosts: web
  become: true

  vars:
    app_name: terraweek-app
    http_port: 80

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

    - name: Create web root
      file:
        path: "/var/www/{{ app_name }}"
        state: directory
        mode: '0755'

    - name: Deploy vhost config
      template:
        src: templates/nginx-vhost.conf.j2
        dest: "/etc/nginx/conf.d/{{ app_name }}.conf"
      notify: Restart Nginx

    - name: Deploy index page
      copy:
        content: "<h1>{{ app_name }}</h1><p>{{ ansible_default_ipv4.address }}</p>"
        dest: "/var/www/{{ app_name }}/index.html"

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```
Run it with --diff to see the rendered template:

```
ansible-playbook template-demo.yml --diff
```
### Key Insight

Templates render **runtime values** using:

* Variables
* Facts
* Filters

---

## Task 2 – Role Structure

```
roles/
  webserver/
    tasks/
      main.yml
    handlers/
      main.yml
    templates/
    files/
    vars/
      main.yml
    defaults/
      main.yml
    meta/
      main.yml
```

### vars vs defaults

| Type     | Priority | Use Case       |
| -------- | -------- | -------------- |
| vars     | High     | Hard overrides |
| defaults | Low      | Safe defaults  |

**Best Practice:**
Always put configurable values in `defaults`, not `vars`.

---

## Task 3 – Custom Webserver Role

### defaults/main.yml

```yaml
---
http_port: 80
app_name: myapp
max_connections: 512
```

### tasks/main.yml

```yaml
---
- name: Install Nginx
  yum:
    name: nginx
    state: present

- name: Deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Restart Nginx

- name: Deploy vhost
  template:
    src: vhost.conf.j2
    dest: "/etc/nginx/conf.d/{{ app_name }}.conf"
  notify: Restart Nginx

- name: Create web root
  file:
    path: "/var/www/{{ app_name }}"
    state: directory

- name: Deploy index
  template:
    src: index.html.j2
    dest: "/var/www/{{ app_name }}/index.html"

- name: Start nginx
  service:
    name: nginx
    state: started
    enabled: true
```

### handlers/main.yml

```yaml
---
- name: Restart Nginx
  service:
    name: nginx
    state: restarted
```

### index.html.j2

```html
<h1>{{ app_name }}</h1>
<p>Host: {{ ansible_hostname }}</p>
<p>IP: {{ ansible_default_ipv4.address }}</p>
<p>Env: {{ app_env | default('dev') }}</p>
```

### Playbook Usage

```yaml
---
- name: Configure web servers
  hosts: web
  become: true

  roles:
    - role: webserver
      vars:
        app_name: terraweek
```

---

## Task 4 – Ansible Galaxy

### Install Role

```
ansible-galaxy install geerlingguy.docker
```

### Use Role

```yaml
---
- name: Setup Docker
  hosts: app
  become: true

  roles:
    - geerlingguy.docker
```

### requirements.yml

```yaml
---
roles:
  - name: geerlingguy.docker
    version: "7.4.1"
  - name: geerlingguy.ntp
```

### Install All

```
ansible-galaxy install -r requirements.yml
```

### Why requirements.yml?

* Version control for roles
* Reproducible environments
* CI/CD friendly
* Team consistency

---

## Task 5 – Ansible Vault

### Create Vault

```
ansible-vault create group_vars/db/vault.yml
```

### Example Content

```yaml
vault_db_password: SuperSecretP@ss
vault_db_root_password: RootPass123
vault_api_key: sk-xyz123
```

### Run Playbook

```
ansible-playbook db-setup.yml --ask-vault-pass
```

### Using Password File

```
ansible-playbook db-setup.yml --vault-password-file .vault_pass
```

### Why password file?

* Required for automation (CI/CD)
* No manual input
* Secure when properly permissioned

---

## Task 6 – Full Integration

### site.yml

```yaml
---
- name: Configure web
  hosts: web
  become: true
  roles:
    - role: webserver
      vars:
        app_name: terraweek

- name: Configure app
  hosts: app
  become: true
  roles:
    - geerlingguy.docker

- name: Configure DB
  hosts: db
  become: true

  tasks:
    - name: Deploy DB config
      template:
        src: templates/db-config.j2
        dest: /etc/db-config.env
        mode: '0600'
```

### db-config.j2

```jinja2
DB_HOST={{ ansible_default_ipv4.address }}
DB_PORT={{ db_port | default(3306) }}
DB_PASSWORD={{ vault_db_password }}
DB_ROOT_PASSWORD={{ vault_db_root_password }}
```

---

## Key Learnings

* Roles enable modular, reusable architecture
* Templates provide dynamic configuration
* Galaxy accelerates development with community roles
* Vault secures sensitive data
* Separation of concerns improves maintainability

---

## Critical Insight

Flat playbooks → **unscalable**
Roles + templates → **production-ready automation**

---
