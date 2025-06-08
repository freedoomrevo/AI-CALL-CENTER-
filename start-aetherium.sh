#!/bin/bash

# Aetherium Complete System Startup Script
# This script handles all dependencies and starts the complete Aetherium system
# Author: OpenHands AI Assistant
# Date: 2025-06-07
# Version: 3.0 - Maximum improvements for robustness, safety, and efficiency

# --- Strict Mode & Error Handling ---
# -e: exit immediately if a command exits with a non-zero status.
# -u: treat unset variables as an error when substituting.
# -o pipefail: the return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status.
set -euo pipefail

# --- Color Definitions for Readable Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Configuration ---
PROJECT_NAME="Aetherium"
VERSION="3.0"
FRONTEND_PORT="12001"
BACKEND_PORT="8000"
DATABASE_PORT="5432"
REDIS_PORT="6379"

# This variable will be set by parse_arguments() to control the main execution flow.
ACTION="start"
SHOW_LOGS=false
COMPOSE_CMD="" # Will be determined in check_dependencies

# --- Logging Functions ---
# Prefixes output with a timestamp and colored status indicators.
print_status() { echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
print_error() { >&2 echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; } # Errors to stderr
print_header() { echo -e "\n${PURPLE}--- $1 ---${NC}"; }
print_info() { echo -e "${CYAN}[$(date +'%H:%M:%S')] 💡 $1${NC}"; }

# --- Core Functions ---

# Function to check for essential dependencies like Docker and Docker Compose.
check_dependencies() {
    print_header "Checking System Dependencies"
    
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        print_info "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start the Docker service."
        exit 1
    fi
    
    # Check for Docker Compose (V2 plugin or V1 standalone)
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        print_error "Docker Compose is not installed. Please install it first."
        print_info "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check available disk space (recommends at least 2GB)
    local available_space_kb
    available_space_kb=$(df -k . | awk 'NR==2 {print $4}')
    if [[ "$available_space_kb" -lt 2097152 ]]; then # 2GB in KB
        print_warning "Low disk space detected (less than 2GB available). This may cause issues."
    fi
    
    print_success "All dependencies are installed and running."
    print_info "Docker: $(docker --version)"
    print_info "Using Compose: $($COMPOSE_CMD version)"
}

# Function to kill processes on specified ports to prevent conflicts.
cleanup_ports() {
    print_header "Checking for Port Conflicts"
    local ports_to_check=("$BACKEND_PORT" "$FRONTEND_PORT" "$DATABASE_PORT" "$REDIS_PORT")
    local killed_processes=false

    for port in "${ports_to_check[@]}"; do
        local pids
        # Use lsof if available (more common on macOS/Linux)
        if command -v lsof >/dev/null 2>&1; then
            pids=$(lsof -t -i :"$port" 2>/dev/null || true)
        # Fallback to fuser (common on Linux)
        elif command -v fuser >/dev/null 2>&1; then
            pids=$(fuser "$port"/tcp 2>/dev/null || true)
        else
            # On the first pass, warn that we can't check ports.
            if [[ "$port" == "${ports_to_check[0]}" ]]; then
                print_warning "Cannot check for port conflicts: 'lsof' or 'fuser' not found. Please install one."
            fi
            continue
        fi

        if [[ -n "$pids" ]]; then
            print_warning "Port $port is in use by PID(s): $pids. Attempting to terminate..."
            # Use kill -9 as a forceful measure to ensure startup.
            kill -9 $pids 2>/dev/null || true
            killed_processes=true
            sleep 1 # Give time for the port to be released
        fi
    done

    if [[ "$killed_processes" = false ]]; then
        print_status "No conflicting processes found on required ports."
    else
        print_success "Port cleanup complete."
    fi
}

# Safely stops and removes all project-related containers, networks, and volumes.
cleanup_existing() {
    print_header "Cleaning Up Previous Project Instance"
    
    print_status "Stopping and removing existing containers, networks, and volumes..."
    # --volumes is crucial for --fresh-start, --remove-orphans cleans up unneeded containers.
    # This is project-scoped and SAFE, unlike `docker system prune`.
    if [[ "${FRESH_START:-false}" == "true" ]]; then
        print_warning "FRESH_START enabled: All data volumes for this project will be deleted."
        $COMPOSE_CMD down --volumes --remove-orphans
    else
        $COMPOSE_CMD down --remove-orphans
    fi

    # Clean up conflicting ports from other applications.
    cleanup_ports
    print_success "Cleanup complete."
}

# Generic function to wait for a service to be ready by executing a command inside its container.
wait_for_service() {
    local service_name="$1"
    local description="$2"
    local max_attempts="$3"
    shift 3
    local check_command=("$@")

    print_status "Waiting for $description..."
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        if $COMPOSE_CMD exec -T "$service_name" "${check_command[@]}" &>/dev/null; then
            print_success "$description is ready."
            return 0
        fi
        
        if (( attempt == max_attempts )); then
            print_error "$description failed to become ready after $max_attempts attempts."
            print_error "Showing last 20 lines of logs for '$service_name':"
            $COMPOSE_CMD logs --tail=20 "$service_name"
            return 1 # Failure
        fi
        
        print_status "Waiting for $description... (attempt $attempt/$max_attempts)"
        sleep 2
    done
}

# Generic function to wait for a URL to become accessible.
wait_for_url() {
    local url="$1"
    local description="$2"
    local max_attempts="$3"
    
    print_status "Waiting for $description at $url..."
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        if curl --fail --silent --head "$url" &>/dev/null; then
            print_success "$description is ready and accessible."
            return 0
        fi

        if (( attempt == max_attempts )); then
            print_warning "$description may not be fully ready, but continuing..."
            print_warning "URL $url was not accessible after $max_attempts attempts."
            return 1 # Non-fatal failure
        fi

        print_status "Waiting for $description... (attempt $attempt/$max_attempts)"
        sleep 3
    done
}

# Main startup sequence functions
build_images() {
    print_header "Building Docker Images"
    if [[ "${REBUILD:-false}" == "true" ]]; then
        print_status "Force rebuilding all images from scratch (--no-cache)..."
        $COMPOSE_CMD build --no-cache --parallel
    else
        print_status "Building images (using cache if possible)..."
        $COMPOSE_CMD build --parallel
    fi
    print_success "Images built successfully."
}

start_core_services() {
    print_header "Starting Core Services (Database & Cache)"
    $COMPOSE_CMD up -d redis database
    
    # Wait for services to be healthy using reliable checks
    wait_for_service "database" "Database" 30 pg_isready -U demo_user -d aetherium_demo
    wait_for_service "redis" "Redis" 15 redis-cli ping
}

start_backend() {
    print_header "Starting Backend API"
    $COMPOSE_CMD up -d backend-api
    
    # Wait for the backend health endpoint
    wait_for_url "http://localhost:$BACKEND_PORT/health" "Backend API" 25
}

start_frontend_and_services() {
    print_header "Starting Frontend and Other Services"
    $COMPOSE_CMD up -d web-frontend nginx modem-manager telegram-bot-interface

    # Wait for the frontend to be available
    wait_for_url "http://localhost:$FRONTEND_PORT" "Web Frontend" 40
}

# Comprehensive system health check function.
run_health_check() {
    print_header "Running System Health Check"
    local healthy_checks=0
    local total_checks=0
    local all_services
    
    # Get all services defined in the compose file
    all_services=$($COMPOSE_CMD config --services)

    for service in $all_services; do
        ((total_checks++))
        local container_id
        container_id=$($COMPOSE_CMD ps -q "$service")
        
        if [[ -z "$container_id" ]]; then
            print_warning "Service '$service' is not running."
            continue
        fi

        local health_status
        health_status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$container_id")

        case "$health_status" in
            healthy)
                print_success "✅ Service '$service' is running and healthy."
                ((healthy_checks++))
                ;;
            starting)
                print_warning "Service '$service' is still starting."
                ;;
            unhealthy)
                print_error "Service '$service' is running but unhealthy."
                ;;
            no-healthcheck)
                # For services without a healthcheck, being 'Up' is our best signal.
                if $COMPOSE_CMD ps "$service" | grep -q "Up"; then
                    print_success "✅ Service '$service' is running (no healthcheck defined)."
                    ((healthy_checks++))
                else
                    print_error "Service '$service' is not running."
                fi
                ;;
            *)
                print_error "Unknown health status for '$service': $health_status"
                ;;
        esac
    done
    
    # Final Summary
    local health_percentage=0
    if (( total_checks > 0 )); then
        health_percentage=$((healthy_checks * 100 / total_checks))
    fi

    echo
    print_header "Health Summary: $healthy_checks / $total_checks Services Healthy ($health_percentage%)"
    if (( health_percentage >= 90 )); then
        print_success "🎉 System is in excellent condition!"
    elif (( health_percentage >= 70 )); then
        print_warning "System is running with some services not fully healthy."
    else
        print_error "System has significant health issues. Please check logs."
    fi
}

# Displays final status and access URLs.
show_status() {
    print_header "System Status Overview"
    $COMPOSE_CMD ps
    
    echo
    print_info "Service URLs:"
    echo -e "  🌐 Frontend:         http://localhost:$FRONTEND_PORT"
    echo -e "  🔧 Backend API:      http://localhost:$BACKEND_PORT"
    echo -e "  📊 API Docs (Swagger): http://localhost:$BACKEND_PORT/docs"
    echo -e "  📊 API Docs (ReDoc):   http://localhost:$BACKEND_PORT/redoc"
    echo -e "  🗄️  Database Port:    $DATABASE_PORT (from localhost)"
    echo -e "  🔴 Redis Port:         $REDIS_PORT (from localhost)"
    echo
    
    run_health_check
}

# Shows recent logs from all services.
show_logs() {
    print_header "Showing Last 15 Lines of Logs from All Services"
    $COMPOSE_CMD logs --tail=15 --timestamps
}

# Displays the help message.
show_usage() {
    echo -e "${PURPLE}"
    cat <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║           🏛️  AETHERIUM STARTUP SCRIPT v3.0 🏛️            ║
║         Advanced AI Communication System                 ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo "A comprehensive script to manage the Aetherium Docker environment."
    echo
    echo -e "${CYAN}USAGE:${NC}"
    echo "  $0 [COMMAND] [OPTIONS]"
    echo
    echo -e "${CYAN}COMMANDS:${NC}"
    echo "  start (default)     Cleans up, builds, and starts all services."
    echo "  stop                Stops and removes all services and networks."
    echo "  health              Runs a health check on running services."
    echo "  help                Shows this help message."
    echo
    echo -e "${CYAN}OPTIONS:${NC}"
    echo "  --fresh-start       Deletes all associated data volumes for a clean slate. (Use with 'start')"
    echo "  --rebuild           Forces a rebuild of all Docker images without using cache. (Use with 'start')"
    echo "  --logs, -l          Shows recent logs after a successful startup."
    echo
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  $0                  # Default start"
    echo "  $0 start --rebuild  # Rebuild images and start"
    echo "  $0 start --fresh-start --logs # Fresh start with data wipe, show logs on completion"
    echo "  $0 stop             # Stop all services"
    echo "  $0 health           # Check system health without starting"
}

# --- Command Functions ---

stop_services() {
    print_header "Stopping All Aetherium Services"
    check_dependencies # We need COMPOSE_CMD
    $COMPOSE_CMD down --remove-orphans
    print_success "All services have been stopped."
}

health_check_only() {
    check_dependencies # We need COMPOSE_CMD and to ensure docker is running
    print_header "Running Health Check Only"
    if ! $COMPOSE_CMD ps -q | grep -q . ; then
        print_error "No services are running. Cannot perform health check."
        print_info "Start the system with: $0 start"
        exit 1
    fi
    run_health_check
}

# Parses command-line arguments to set global variables and control flow.
parse_arguments() {
    # Default action if no command is given
    if [[ $# -eq 0 ]] || [[ "$1" != "start" && "$1" != "stop" && "$1" != "health" && "$1" != "help" ]]; then
        ACTION="start"
    else
        ACTION="$1"
        shift
    fi

    # Parse remaining options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                ACTION="help"
                shift
                ;;
            --logs|-l)
                SHOW_LOGS=true
                shift
                ;;
            --fresh-start)
                export FRESH_START=true
                shift
                ;;
            --rebuild)
                export REBUILD=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                ACTION="help"
                break
                ;;
        esac
    done
}

# --- Main Execution Block ---

main() {
    # Display startup banner
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║    🎯 AETHERIUM - Advanced AI Communication System 🎯       ║"
    echo "║                   Version $VERSION - Enhanced                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # The main startup sequence
    check_dependencies
    cleanup_existing
    build_images
    start_core_services
    start_backend
    start_frontend_and_services
    
    print_success "🎉 Aetherium system startup sequence completed!"
    
    show_status
    
    if [[ "$SHOW_LOGS" = true ]]; then
        show_logs
    fi
    
    echo
    print_info "🔧 Useful commands:"
    echo "  - View logs: $COMPOSE_CMD logs -f [service-name]"
    echo "  - Stop all: $0 stop"
    echo "  - Check health: $0 health"
    echo
    print_success "✨ Aetherium is ready for use at: http://localhost:$FRONTEND_PORT"
}

# Trap to ensure a clean exit message on script interruption
trap 'echo; print_warning "Script interrupted by user. Exiting."; exit 1' INT

# --- Script Entry Point ---
# Parse arguments first to determine the action, then execute.
parse_arguments "$@"

case "$ACTION" in
    start)
        main
        ;;
    stop)
        stop_services
        ;;
    health)
        health_check_only
        ;;
    help)
        show_usage
        ;;
    *)
        print_error "Invalid action '$ACTION'. See usage below."
        show_usage
        exit 1
        ;;
esac

exit 0
