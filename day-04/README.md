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
ansible-playbook template-demo.yml --diff -i ../inventory.ini
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
Every directory contains a main.yml that Ansible loads automatically. You only create the directories you need.

Generate a skeleton with:

```
ansible-galaxy init roles/webserver

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

### templates/index.html.j2

```html
<h1>{{ app_name }}</h1>
<p>Host: {{ ansible_hostname }}</p>
<p>IP: {{ ansible_default_ipv4.address }}</p>
<p>Env: {{ app_env | default('dev') }}</p>
```
Create the vhost.conf.j2 and nginx.conf.j2 templates yourself based on what you learned in Task 1.


### Playbook Usage
Now call the role from a playbook site.yml:
```yaml
---
- name: Configure web servers
  hosts: web
  become: true

  roles:
    - role: webserver
      vars:
        app_name: terraweek
        http_port: 80
```
Run it:

```bash
 ansible-playbook site.yml -i ../inventory.ini
```
Verify: Curl the web server. Does the custom page load?
---

## Task 4 – Ansible Galaxy

Ansible Galaxy is a marketplace of pre-built roles.

1. Search for roles:
```
ansible-galaxy search nginx --platforms EL
ansible-galaxy search mysql
```
2. Install a role from Galaxy:
```
ansible-galaxy install geerlingguy.docker
```
3. Check where it was installed:
```
ansible-galaxy list
```
4. Use the installed role -- create docker-setup.yml:

```yaml
---
- name: Setup Docker
  hosts: app
  become: true

  roles:
    - geerlingguy.docker
```
Run it -- Docker gets installed with a single role call.

5. Use a requirements file for managing multiple roles. Create requirements.yml:

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

1. **Create an encrypted file:**
```bash
ansible-vault create group_vars/db/vault.yml
```
It will ask for a vault password, then open an editor. Add:
```yaml
vault_db_password: SuperSecretP@ssw0rd
vault_db_root_password: R00tP@ssw0rd123
vault_api_key: sk-abc123xyz789
```
Save and exit. Open the file with `cat` -- it is fully encrypted.

2. **Edit an encrypted file:**
```bash
ansible-vault edit group_vars/db/vault.yml
```

3. **View without editing:**
```bash
ansible-vault view group_vars/db/vault.yml
```

4. **Encrypt an existing file:**
```bash
ansible-vault encrypt group_vars/db/secrets.yml
```

5. **Use vault variables in a playbook** -- create `db-setup.yml`:
```yaml
---
- name: Configure database
  hosts: db
  become: true

  tasks:
    - name: Show DB password (never do this in production)
      debug:
        msg: "DB password is set: {{ vault_db_password | length > 0 }}"
```

Run with the vault password:
```bash
ansible-playbook db-setup.yml --ask-vault-pass
```

6. **Use a password file** (better for CI/CD):
```bash
echo "YourVaultPassword" > .vault_pass
chmod 600 .vault_pass
echo ".vault_pass" >> .gitignore

ansible-playbook db-setup.yml --vault-password-file .vault_pass
```

Or set it in `ansible.cfg`:
```ini
[defaults]
vault_password_file = .vault_pass
```

**Document:** Why is `--vault-password-file` better than `--ask-vault-pass` for automated pipelines?

---

### Task 6: Combine Roles, Templates, and Vault
Write a complete `site.yml` that uses everything you learned today:

```yaml
---
- name: Configure web servers
  hosts: web
  become: true
  roles:
    - role: webserver
      vars:
        app_name: terraweek
        http_port: 80

- name: Configure app servers with Docker
  hosts: app
  become: true
  roles:
    - geerlingguy.docker

- name: Configure database servers
  hosts: db
  become: true
  tasks:
    - name: Create DB config with secrets
      template:
        src: templates/db-config.j2
        dest: /etc/db-config.env
        owner: root
        mode: '0600'
```

Create `templates/db-config.j2`:
```jinja2
# Database Configuration -- Managed by Ansible
DB_HOST={{ ansible_default_ipv4.address }}
DB_PORT={{ db_port | default(3306) }}
DB_PASSWORD={{ vault_db_password }}
DB_ROOT_PASSWORD={{ vault_db_root_password }}
```

Run:
```bash
ansible-playbook site1.yml -i ../inventory.ini --vault-password-file ../.vault_pass

```

**Verify:** SSH into the db server and check `/etc/db-config.env`. Are the secrets rendered correctly? Is the file permission `600`?

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
