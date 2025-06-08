#!/bin/bash
# Aetherium Development Environment Setup Script
# Comprehensive setup for local development

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Aetherium"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHON_VERSION="3.11"
NODE_VERSION="18"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}" >&2
}

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        info "Detected Linux system"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        info "Detected macOS system"
    else
        warn "Unsupported operating system: $OSTYPE (continuing anyway)"
        OS="unknown"
    fi
    
    # Check Docker
    if command_exists docker; then
        success "Docker found: $(docker --version)"
    else
        error "Docker not found! Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check Docker Compose
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        success "Docker Compose found"
    else
        error "Docker Compose not found! Please install Docker Compose."
        exit 1
    fi
    
    # Check Git
    if command_exists git; then
        success "Git found: $(git --version)"
    else
        error "Git not found! Please install Git first."
        exit 1
    fi
}

# Setup environment configuration
setup_environment_config() {
    log "Setting up environment configuration..."
    
    cd "$PROJECT_DIR"
    
    # Copy environment template if .env doesn't exist
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            info "Created .env file from template"
        else
            warn ".env.example not found, creating basic .env file"
            cat > .env << 'EOF'
# Aetherium Development Environment
ENVIRONMENT=development
DEBUG=true

# Database
POSTGRES_DB=aetherium_demo
POSTGRES_USER=demo_user
POSTGRES_PASSWORD=demo_password_123
DATABASE_URL=postgresql://demo_user:demo_password_123@localhost:5432/aetherium_demo

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT
JWT_SECRET_KEY=dev_secret_key_change_in_production
JWT_ALGORITHM=HS256

# API Keys (add your keys here)
GEMINI_API_KEY=your_gemini_api_key_here
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Logging
LOG_LEVEL=DEBUG
EOF
        fi
        success "Environment configuration created"
    else
        info ".env file already exists"
    fi
}

# Setup Python environment
setup_python_environment() {
    log "Setting up Python environment..."
    
    cd "$PROJECT_DIR/backend"
    
    # Check Python version
    if command_exists python3; then
        PYTHON_CURRENT=$(python3 --version | cut -d' ' -f2)
        info "Python found: $PYTHON_CURRENT"
    else
        error "Python 3 not found! Please install Python 3.11+"
        exit 1
    fi
    
    # Create virtual environment if it doesn't exist
    if [[ ! -d "venv" ]]; then
        info "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment and install dependencies
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install dependencies
    if [[ -f "requirements.txt" ]]; then
        info "Installing Python dependencies..."
        pip install -r requirements.txt
    fi
    
    # Install development dependencies
    pip install pytest pytest-asyncio pytest-cov black isort flake8 mypy
    
    success "Python environment setup completed"
}

# Setup Node.js environment
setup_node_environment() {
    log "Setting up Node.js environment..."
    
    cd "$PROJECT_DIR/frontend"
    
    # Check Node.js
    if command_exists node; then
        NODE_CURRENT=$(node --version)
        info "Node.js found: $NODE_CURRENT"
    else
        error "Node.js not found! Please install Node.js 18+"
        exit 1
    fi
    
    # Check npm
    if command_exists npm; then
        info "npm found: $(npm --version)"
    else
        error "npm not found! Please install npm."
        exit 1
    fi
    
    # Install dependencies
    if [[ -f "package.json" ]]; then
        info "Installing Node.js dependencies..."
        npm install
    fi
    
    success "Node.js environment setup completed"
}

# Create development scripts
create_dev_scripts() {
    log "Creating development scripts..."
    
    cd "$PROJECT_DIR"
    
    # Create start script
    if [[ ! -f "start-dev.sh" ]]; then
        cat > start-dev.sh << 'EOF'
#!/bin/bash
# Start Aetherium development environment

echo "🚀 Starting Aetherium Development Environment..."

# Check if Docker services are running
if ! docker ps | grep -q aetherium; then
    echo "Starting Docker services..."
    docker compose up -d database redis
    sleep 5
fi

# Start backend
echo "Starting backend..."
cd backend
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# Start frontend
echo "Starting frontend..."
cd ../frontend
npm run dev -- --host 0.0.0.0 --port 12001 &
FRONTEND_PID=$!

echo ""
echo "✅ Services started:"
echo "   🌐 Frontend: http://localhost:12001"
echo "   🔧 Backend: http://localhost:8000"
echo "   📚 API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for Ctrl+C
trap "echo 'Stopping services...'; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT
wait
EOF
        chmod +x start-dev.sh
        success "Created start-dev.sh script"
    fi
    
    # Create test script
    if [[ ! -f "run-tests.sh" ]]; then
        cat > run-tests.sh << 'EOF'
#!/bin/bash
# Run all tests

echo "🧪 Running Aetherium Tests..."

# Backend tests
echo "Running backend tests..."
cd backend
if [[ -d "venv" ]]; then
    source venv/bin/activate
    pytest tests/ -v --cov=. || echo "Backend tests completed with issues"
else
    echo "Python virtual environment not found. Run setup_dev_env.sh first."
fi

# Frontend tests
echo "Running frontend tests..."
cd ../frontend
if [[ -f "package.json" ]]; then
    npm test || echo "Frontend tests completed with issues"
else
    echo "Frontend dependencies not installed. Run setup_dev_env.sh first."
fi

echo "✅ All tests completed"
EOF
        chmod +x run-tests.sh
        success "Created run-tests.sh script"
    fi
}

# Setup IDE configuration
setup_ide_config() {
    log "Setting up IDE configuration..."
    
    cd "$PROJECT_DIR"
    
    # VS Code settings
    mkdir -p .vscode
    
    if [[ ! -f ".vscode/settings.json" ]]; then
        cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "./backend/venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.sortImports.args": ["--profile", "black"],
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "files.exclude": {
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/node_modules": true,
        "**/venv": true
    },
    "typescript.preferences.importModuleSpecifier": "relative"
}
EOF
        success "Created VS Code settings"
    fi
    
    # VS Code launch configuration
    if [[ ! -f ".vscode/launch.json" ]]; then
        cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: FastAPI",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/backend/main.py",
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}/backend",
            "env": {
                "PYTHONPATH": "${workspaceFolder}/backend"
            }
        },
        {
            "name": "Python: Tests",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": ["tests/", "-v"],
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}/backend"
        }
    ]
}
EOF
        success "Created VS Code launch configuration"
    fi
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    cd "$PROJECT_DIR"
    
    # Check if all required files exist
    local required_files=(
        ".env"
        "docker-compose.yml"
        "backend/requirements.txt"
        "frontend/package.json"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            success "Found: $file"
        else
            warn "Missing: $file"
        fi
    done
    
    # Test Docker services
    info "Testing Docker services..."
    if docker compose config >/dev/null 2>&1; then
        success "Docker Compose configuration is valid"
    else
        warn "Docker Compose configuration has issues"
    fi
    
    # Check Python environment
    if [[ -f "backend/venv/bin/python" ]]; then
        success "Python virtual environment ready"
    else
        warn "Python virtual environment not found"
    fi
    
    # Check Node modules
    if [[ -d "frontend/node_modules" ]]; then
        success "Node.js dependencies installed"
    else
        warn "Node.js dependencies not installed"
    fi
}

# Main setup function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║        🏛️  AETHERIUM DEVELOPMENT SETUP SCRIPT 🏛️           ║"
    echo "║                                                              ║"
    echo "║     Setting up your local development environment...        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    # Check if running from project directory
    if [[ ! -f "$PROJECT_DIR/docker-compose.yml" ]]; then
        error "Please run this script from the Aetherium project root directory"
        exit 1
    fi
    
    # Run setup steps
    check_system_requirements
    setup_environment_config
    setup_python_environment
    setup_node_environment
    create_dev_scripts
    setup_ide_config
    verify_installation
    
    echo -e "\n${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                    🎉 SETUP COMPLETED! 🎉                   ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. 🔑 Edit .env file and add your API keys:"
    echo "   - GEMINI_API_KEY=your_actual_api_key"
    echo "   - TELEGRAM_BOT_TOKEN=your_bot_token"
    echo ""
    echo "2. 🚀 Start development environment:"
    echo "   ./start-dev.sh"
    echo ""
    echo "3. 🧪 Run tests:"
    echo "   ./run-tests.sh"
    echo ""
    echo "4. 📚 Access services:"
    echo "   - Frontend: http://localhost:12001"
    echo "   - Backend: http://localhost:8000"
    echo "   - API Docs: http://localhost:8000/docs"
    echo ""
    echo "5. 🐳 Or use Docker Compose:"
    echo "   docker compose up -d"
    
    success "Aetherium development environment is ready! 🚀"
}

# Run main function
main "$@"