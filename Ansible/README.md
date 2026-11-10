# Quickstart
Run jenkins docker compose
```bash
ansible-playbook -Ki hosts.ini playbooks/test_connection.yml
```

# Ansible and Docker
Create an ansible playbook that will deploy a docker-compose application containing two
services:
1. Web server that will offer a basic “Hello World” HTML page.
2. Stateful service that will keep a counter-hit from the web server in a separate DB container.