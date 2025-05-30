# CTFd Platform Setup with Vagrant and Docker

This project sets up a complete CTFd (Capture The Flag) platform using Vagrant for VM management and Docker for containerized services. The setup includes CTFd, MariaDB, Redis, and Nginx as a reverse proxy.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-Overview)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Components](#components)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Daily Operations](#daily-operations)
- [Technical Details](#technical-details)

## Overview

This project automates the deployment of a CTFd platform with the following architecture:
- **Vagrant VM**: Ubuntu 22.04 LTS host environment
- **Docker Containers**: CTFd application, MariaDB database, Redis cache
- **Nginx**: Reverse proxy for web traffic
- **Port Forwarding**: Access from host machine via localhost:8080

## Architecture Overview
<img width="1586" alt="Exercise 03 - Cloud instance initialization (5)" src="https://github.com/user-attachments/assets/a8176ef2-24a0-48b6-ac16-8a5edba7a9f0" />

## Prerequisites

Before starting, ensure you have the following installed on your host machine:

- [VirtualBox](https://www.virtualbox.org/) (7.0 or later)
- [Vagrant](https://www.vagrantup.com/) (2.3 or later)
- At least 4GB free RAM
- At least 10GB free disk space
## Architecture Overview
## Project Structure

```
ansible-ctfd-project/
├── Vagrantfile --------------------------> # VM configuration
├── setup.sh -----------------------------> # Automated setup script
├── README.md ----------------------------> # This file
├── playbook.yml -------------------------> # Main Ansible playbook
├── group_vars/ --------------------------> # Ansible group variables
│   └── all.yml --------------------------> # Common variables
├── inventory/ ---------------------------> # Ansible inventory configuration
│   └── hosts.yml ------------------------> # Host definitions
└── roles/ -------------------------------> # Ansible roles structure
    ├── docker/ --------------------------> # Docker installation role
    │   ├── handlers/
    │   │   └── main.yml -----------------> # Docker service handlers
    │   └── tasks/
    │       └── main.yml -----------------> # Docker installation tasks
    ├── ctfd/ ----------------------------> # CTFd application role
    │   ├── tasks/
    │   │   └── main.yml -----------------> # CTFd setup tasks
    │   └── templates/
    │       └── docker-compose.yml.j2 ----> # Docker Compose template
    └── nginx/ ---------------------------> # Nginx reverse proxy role
        └── tasks/
            └── main.yml -----------------> # Nginx configuration tasks
```

## Quick Start

### Initial Setup

1. **Clone or create the project directory:**
   ```bash
   mkdir -p exercise-04-software-provisioning-and-configuration-management/ansible-ctfd-project
   cd exercise-04-software-provisioning-and-configuration-management/ansible-ctfd-project
   ```

2. **Start the deployment:**
   ```bash
   vagrant up
   ```

3. **Access CTFd:**
   - Open your browser and go to: `http://localhost:8080`
   - Complete the initial setup wizard

### First-Time CTFd Configuration

When you first access CTFd, you'll need to configure:

1. **General**: Event name and description
2. **Mode**: Team or individual competition mode
3. **Settings**: Visibility and participation rules
4. **Administration**: Create admin user account
5. **Style**: Optional branding and themes
6. **Date & Time**: Competition schedule (optional)

## Components

### Core Services

| Service | Description | Port | Container Name |
|---------|-------------|------|----------------|
| **CTFd** | Main CTF platform | 8000 | ctfd-ctfd-1 |
| **MariaDB** | Database server | 3306 | ctfd-db-1 |
| **Redis** | Cache server | 6379 | ctfd-cache-1 |
| **Nginx** | Reverse proxy | 80 | (host service) |

### Network Configuration

- **Host Access**: `localhost:8080` → **Vagrant VM**: `port 8000`
- **VM Internal**: `Nginx:80` → **CTFd Container**: `port 8000`
- **Container Network**: CTFd ↔ MariaDB ↔ Redis

## Configuration

### Key Configuration Files

#### Vagrantfile
- VM specifications: 2GB RAM, 2 CPUs
- Port forwarding: guest:8000 → host:8080
- Provisioning script execution

#### docker-compose.yml (auto-generated)
```yaml
services:
  ctfd:
    image: ctfd/ctfd
    ports: ["8000:8000"]
    environment:
      - DATABASE_URL=mysql+pymysql://ctfd:ctfd@db/ctfd
      - REDIS_URL=redis://cache:6379
  
  db:
    image: mariadb:10.6
    environment:
      - MYSQL_ROOT_PASSWORD=ctfd
      - MYSQL_USER=ctfd
      - MYSQL_PASSWORD=ctfd
      - MYSQL_DATABASE=ctfd
  
  cache:
    image: redis:6
```

#### Nginx Configuration
```nginx
server {
    listen 80;
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Troubleshooting

### Common Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Port conflict** | "Address already in use" | Change host port in Vagrantfile |
| **Container restart loop** | CTFd keeps restarting | Check Docker logs: `docker logs ctfd-ctfd-1` |
| **Database connection** | "Connection refused" errors | Verify MariaDB container: `docker ps` |
| **Web interface 502** | Bad Gateway error | Check Nginx and CTFd status |

### Diagnostic Commands

```bash
# SSH into VM
vagrant ssh

# Check all containers
docker ps

# View container logs
docker logs ctfd-ctfd-1
docker logs ctfd-db-1
docker logs ctfd-cache-1

# Check Nginx status
sudo systemctl status nginx

# Test database connection
docker exec -it ctfd-db-1 mysql -u ctfd -pctfd -e "SHOW DATABASES;"
```

## Daily Operations

### Starting Up
```bash
# From project directory
vagrant up

# If containers aren't running
vagrant ssh
cd /opt/ctfd
docker-compose up -d
```

### Shutting Down
```bash
# Exit SSH session
exit

# Stop VM
vagrant halt
```

### Restarting Services
```bash
# Restart all containers
docker-compose restart

# Restart specific service
docker restart ctfd-ctfd-1

# Restart Nginx
sudo systemctl restart nginx
```

## Technical Details

### System Requirements
- **VM**: Ubuntu 22.04 LTS (2GB RAM, 2 CPUs)
- **Docker**: Latest CE version
- **Docker Compose**: v2.18.1+

### Data Persistence
- **Database**: `/opt/ctfd/data/mysql` (MariaDB data)
- **Redis**: `/opt/ctfd/data/redis` (Cache data)
- **CTFd Files**: `/opt/ctfd/data/CTFd/` (Logs, uploads)

### Security Considerations
- Default credentials are used for development
- Database is not exposed to host network
- Redis is not password-protected (internal use only)
- Consider changing default passwords for production use

### Performance Notes
- VM configured with 2GB RAM (adjust if needed)
- Database and cache use default configurations
- Monitor resource usage with `docker stats`

## Additional Notes

### Customization
- Modify `setup.sh` to change default configurations
- Update `docker-compose.yml` template in setup script for service changes
- Adjust Vagrant VM specs in `Vagrantfile` as needed

### Backup Recommendations
- Regular backup of `/opt/ctfd/data/` directory
- Export CTFd challenges and user data through admin interface
- Consider automated backup scripts for production environments

### Development vs Production
This setup is designed for development and testing. For production deployment:
- Use proper SSL certificates
- Implement proper secret management
- Configure database backups
- Set up monitoring and logging
- Use production-grade database configurations

---

**Project**: Exercise 04 - Software Provisioning and Configuration Management  
**Course**: IKT114 - IT Orchestration  
**Institution**: University of Agder
