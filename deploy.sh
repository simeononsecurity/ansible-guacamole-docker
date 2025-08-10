#!/bin/bash

# Apache Guacamole Docker Deployment Script
# This script provides a simple way to deploy Guacamole with Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from .env.example..."
        if [ -f .env.example ]; then
            cp .env.example .env
            print_warning "Please edit .env file with your configuration before continuing."
            print_warning "At minimum, set a secure POSTGRES_PASSWORD."
            read -p "Press Enter to continue after editing .env file..."
        else
            print_error ".env.example file not found. Cannot create .env file."
            exit 1
        fi
    fi
    print_success ".env file found"
}

# Generate secure password if needed
generate_password() {
    if grep -q "change_this_secure_password" .env; then
        print_warning "Default password detected in .env file"
        read -p "Generate a secure password automatically? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SECURE_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
            sed -i.bak "s/change_this_secure_password/$SECURE_PASSWORD/g" .env
            print_success "Secure password generated and saved to .env"
            print_warning "Password: $SECURE_PASSWORD"
            print_warning "Please save this password securely!"
        fi
    fi
}

# Pull Docker images
pull_images() {
    print_status "Pulling Docker images..."
    docker-compose pull
    print_success "Docker images pulled successfully"
}

# Start services
start_services() {
    print_status "Starting Guacamole services..."
    docker-compose up -d
    print_success "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL..."
    timeout 60 bash -c 'until docker-compose exec -T postgres pg_isready -U guacamole_user; do sleep 2; done'
    
    # Wait for Guacamole
    print_status "Waiting for Guacamole web interface..."
    GUACAMOLE_PORT=$(grep GUACAMOLE_PORT .env | cut -d '=' -f2 | tr -d '"' || echo "8080")
    timeout 120 bash -c "until curl -f http://localhost:$GUACAMOLE_PORT/guacamole/ &>/dev/null; do sleep 5; done"
    
    print_success "All services are ready!"
}

# Display access information
show_access_info() {
    GUACAMOLE_PORT=$(grep GUACAMOLE_PORT .env | cut -d '=' -f2 | tr -d '"' || echo "8080")
    SERVER_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
    
    echo
    echo "=========================================="
    echo "🎉 Guacamole Deployment Complete!"
    echo "=========================================="
    echo
    echo "Access Information:"
    echo "  URL: http://$SERVER_IP:$GUACAMOLE_PORT/guacamole"
    echo "  Username: guacadmin"
    echo "  Password: guacadmin"
    echo
    echo "⚠️  IMPORTANT SECURITY NOTES:"
    echo "  1. Change the default password immediately!"
    echo "  2. Create additional users and disable guacadmin if not needed"
    echo "  3. Consider setting up SSL/TLS with a reverse proxy"
    echo
    echo "Useful Commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart services: docker-compose restart"
    echo
    echo "For more information, see README.md"
    echo "=========================================="
}

# Main deployment function
main() {
    echo "=========================================="
    echo "Apache Guacamole Docker Deployment"
    echo "=========================================="
    echo
    
    check_docker
    check_env_file
    generate_password
    pull_images
    start_services
    wait_for_services
    show_access_info
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping Guacamole services..."
        docker-compose down
        print_success "Services stopped"
        ;;
    "restart")
        print_status "Restarting Guacamole services..."
        docker-compose restart
        print_success "Services restarted"
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "status")
        docker-compose ps
        ;;
    "update")
        print_status "Updating Guacamole..."
        docker-compose pull
        docker-compose up -d
        print_success "Update complete"
        ;;
    "backup")
        print_status "Creating database backup..."
        BACKUP_FILE="guacamole_backup_$(date +%Y%m%d_%H%M%S).sql"
        docker-compose exec -T postgres pg_dump -U guacamole_user guacamole_db > "$BACKUP_FILE"
        print_success "Backup created: $BACKUP_FILE"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [COMMAND]"
        echo
        echo "Commands:"
        echo "  (no command)  Deploy Guacamole"
        echo "  stop          Stop all services"
        echo "  restart       Restart all services"
        echo "  logs          Show service logs"
        echo "  status        Show service status"
        echo "  update        Update and restart services"
        echo "  backup        Create database backup"
        echo "  help          Show this help message"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        print_status "Use '$0 help' for usage information"
        exit 1
        ;;
esac
