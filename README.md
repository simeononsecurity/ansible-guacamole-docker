# Apache Guacamole Docker Deployment

A complete Docker Compose setup for deploying Apache Guacamole with PostgreSQL database and optional Ansible automation.

## Features

- **Complete Stack**: Guacamole web interface, guacd daemon, and PostgreSQL database
- **Security**: Built-in brute force protection and secure database configuration
- **Automation**: Ansible playbook for automated deployment
- **Flexibility**: Support for Traefik reverse proxy
- **Production Ready**: Persistent volumes and proper restart policies

## Quick Start

### Manual Deployment

1. **Clone and configure**:
   ```bash
   git clone https://github.com/your-username/guacamole-docker-deployment.git
   cd guacamole-docker-deployment
   cp .env.example .env
   ```

2. **Edit environment variables**:
   ```bash
   nano .env
   ```
   Set your PostgreSQL password and other configuration options.

3. **Deploy**:
   ```bash
   docker-compose up -d
   ```

4. **Access Guacamole**:
   - URL: `http://your-server:8080/guacamole`
   - Default username: `guacadmin`
   - Default password: `guacadmin`
   - **Important**: Change the default password immediately!

### Ansible Deployment

1. **Configure inventory**:
   ```bash
   cd ansible
   cp inventory.yml.example inventory.yml
   nano inventory.yml
   ```

2. **Deploy with Ansible**:
   ```bash
   ansible-playbook -i inventory.yml playbook.yml
   ```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | `guacamole_password` | PostgreSQL password |
| `GUACAMOLE_PORT` | `8080` | Port for Guacamole web interface |

### Traefik Integration

To use with Traefik reverse proxy, uncomment and configure these variables in your inventory:

```yaml
traefik_enabled: true
traefik_host: "guacamole.example.com"
traefik_entrypoint: "websecure"
traefik_cert_resolver: "letsencrypt"
```


## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Guacamole     │    │      guacd      │    │   PostgreSQL    │
│  Web Interface  │◄──►│     Daemon      │    │    Database     │
│   (Port 8080)   │    │   (Port 4822)   │    │   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Services

### PostgreSQL Database
- **Image**: `postgres:17`
- **Purpose**: Stores user accounts, connections, and session history
- **Persistence**: `postgres_data` volume
- **Initialization**: Automatic schema creation via `init/01-initdb.sql`

### Guacd Daemon
- **Image**: `guacamole/guacd:latest`
- **Purpose**: Handles remote desktop protocol connections (VNC, RDP, SSH, etc.)
- **Persistence**: `guacd_data` volume

### Guacamole Web Interface
- **Image**: `guacamole/guacamole:latest`
- **Purpose**: Web-based remote desktop gateway
- **Features**: User management, connection management, session recording
- **Persistence**: `guacamole_data` volume

## Security Features

- **Brute Force Protection**: Automatic IP blocking after failed login attempts
- **Secure Database**: Isolated network and strong password requirements
- **SSL Support**: Ready for Traefik SSL termination
- **User Management**: Role-based access control

## Maintenance

### Backup Database
```bash
docker exec guacamole-postgres pg_dump -U guacamole_user guacamole_db > backup.sql
```

### Restore Database
```bash
docker exec -i guacamole-postgres psql -U guacamole_user guacamole_db < backup.sql
```

### View Logs
```bash
docker-compose logs -f guacamole
docker-compose logs -f postgres
docker-compose logs -f guacd
```

### Update Images
```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL container is running: `docker-compose ps`
   - Verify database credentials in `.env` file
   - Check logs: `docker-compose logs postgres`

2. **Guacamole Won't Start**
   - Ensure database is fully initialized before starting Guacamole
   - Check logs: `docker-compose logs guacamole`
   - Verify all environment variables are set correctly

3. **Can't Connect to Remote Hosts**
   - Check guacd container is running: `docker-compose ps`
   - Verify network connectivity from guacd container
   - Check guacd logs: `docker-compose logs guacd`

### Health Checks

```bash
# Check all services are running
docker-compose ps

# Test database connection
docker exec guacamole-postgres psql -U guacamole_user -d guacamole_db -c "SELECT version();"

# Test Guacamole web interface
curl -f http://localhost:8080/guacamole/ || echo "Guacamole not responding"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Support

- [Apache Guacamole Documentation](https://guacamole.apache.org/doc/gug/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Ansible Documentation](https://docs.ansible.com/)
