#!/usr/bin/env bash
set -e  # Exit immediately if a command exits with a non-zero status

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /tmp/setup.log
    if [ "$2" != "silent" ]; then
        echo "$1"
    fi
}

# Update system
log "Updating system packages..." silent
apt-get update -qq
apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release

# Install Docker
log "Installing Docker..." silent
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io

# Install Docker Compose
log "Installing Docker Compose..." silent
curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add vagrant user to docker group
log "Configuring user permissions..." silent
usermod -aG docker vagrant

# Setup CTFd
log "Setting up CTFd..." silent
mkdir -p /opt/ctfd
cd /opt/ctfd

# Create docker-compose.yml
log "Creating Docker Compose configuration..." silent
cat > docker-compose.yml << 'EOL'
version: '3'

services:
  ctfd:
    image: ctfd/ctfd
    restart: always
    ports:
      - "8000:8000"
    environment:
      - UPLOAD_FOLDER=/var/uploads
      - DATABASE_URL=mysql+pymysql://ctfd:ctfd@db/ctfd
      - REDIS_URL=redis://cache:6379
    volumes:
      - ./data/CTFd/logs:/opt/CTFd/CTFd/logs
      - ./data/CTFd/uploads:/opt/CTFd/CTFd/uploads
      - ./data/CTFd/plugins:/opt/CTFd/CTFd/plugins
      - ./data/CTFd/themes:/opt/CTFd/CTFd/themes
    depends_on:
      - db
      - cache

  db:
    image: mariadb:10.6
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=ctfd
      - MYSQL_USER=ctfd
      - MYSQL_PASSWORD=ctfd
      - MYSQL_DATABASE=ctfd
    volumes:
      - ./data/mysql:/var/lib/mysql

  cache:
    image: redis:6
    restart: always
    volumes:
      - ./data/redis:/data
EOL

# Start CTFd
log "Starting CTFd containers..." silent
docker-compose pull -q
docker-compose up -d

# Install Nginx
log "Installing and configuring Nginx..." silent
apt-get install -y -qq nginx

# Configure Nginx
log "Setting up Nginx reverse proxy..." silent
cat > /etc/nginx/sites-available/ctfd << 'EOL'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://172.17.0.1:8000;  # Use Docker host IP instead of localhost
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }
}
EOL

# Enable Nginx site
ln -sf /etc/nginx/sites-available/ctfd /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Check services
log "Verifying services..." silent
docker ps >> /tmp/setup.log
systemctl status nginx --no-pager >> /tmp/setup.log

log "CTFd setup complete!" silent
log "Docker containers:" silent
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" >> /tmp/setup.log

log "Setup completed successfully!" silent
echo "You can access CTFd at http://localhost:8080"