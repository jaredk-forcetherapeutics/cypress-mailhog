#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to script directory
cd "$(dirname "$0")"

# Helper Functions
check_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
  fi
}

has_compose_conflict() {
  pgrep -f "docker-compose.*test-server" >/dev/null 2>&1
}

confirm() {
  echo -n -e "${YELLOW}$1 [y/N]: ${NC}"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

case "$1" in
  start)
    check_docker
    
    if has_compose_conflict; then
      echo -e "${YELLOW}Warning: docker-compose is already running${NC}"
      if confirm "Kill existing processes and continue?"; then
        pkill -9 -f "docker-compose.*test-server"
        sleep 1
      else
        exit 1
      fi
    fi
    
    echo -e "${GREEN}Starting test server...${NC}"
    docker-compose up -d
    echo -e "${YELLOW}Waiting for services to initialize...${NC}"
    sleep 15
    ./verify-services.sh
    ;;
    
  stop)
    check_docker
    echo -e "${YELLOW}Stopping test server...${NC}"
    docker-compose down
    echo -e "${GREEN}Services stopped${NC}"
    ;;
    
  restart)
    check_docker
    echo -e "${YELLOW}Restarting test server...${NC}"
    docker-compose down
    docker-compose up -d
    sleep 5
    ./verify-services.sh
    ;;
    
  logs)
    docker-compose logs -f "${2:-}"
    ;;
    
  status)
    ./verify-services.sh
    ;;
    
  shell)
    echo -e "${GREEN}Opening shell in web container...${NC}"
    docker-compose exec web bash
    ;;
    
  composer)
    shift
    echo -e "${GREEN}Running: composer $@${NC}"
    docker-compose exec web composer "$@"
    ;;
    
  clean)
    check_docker
    
    if ! confirm "Remove all containers and volumes?"; then
      echo -e "${YELLOW}Aborted${NC}"
      exit 0
    fi
    
    echo -e "${RED}Removing containers and volumes...${NC}"
    docker-compose down -v
    echo -e "${GREEN}Cleaned up${NC}"
    ;;
    
  check)
    echo -e "${GREEN}System Check${NC}"
    echo "========================"
    
    # Docker
    if docker info >/dev/null 2>&1; then
      echo -e "Docker: ${GREEN}✓${NC}"
    else
      echo -e "Docker: ${RED}✗${NC}"
    fi
    
    # Compose processes
    if has_compose_conflict; then
      echo -e "docker-compose: ${YELLOW}⚠ Running${NC}"
    else
      echo -e "docker-compose: ${GREEN}✓ Not running${NC}"
    fi
    
    # Containers
    running=$(docker ps -q --filter "name=test-server" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$running" -gt 0 ]; then
      echo -e "Containers: ${GREEN}$running running${NC}"
    else
      echo -e "Containers: ${YELLOW}None${NC}"
    fi
    
    # Ports
    for port in 3000 8090 1025; do
      if lsof -i :$port >/dev/null 2>&1; then
        echo -e "Port $port: ${YELLOW}⚠ In use${NC}"
      else
        echo -e "Port $port: ${GREEN}✓ Free${NC}"
      fi
    done
    ;;
    
  reset)
    check_docker
    
    echo -e "${RED}This will kill all processes and delete everything${NC}"
    echo -e "${YELLOW}Warning: This will delete the vendor/ directory${NC}"
    echo -e "${YELLOW}Composer will reinstall dependencies on next startup (15-30 sec)${NC}"
    
    if ! confirm "Continue with reset?"; then
      echo -e "${YELLOW}Aborted${NC}"
      exit 0
    fi
    
    # Kill processes
    echo "Killing docker-compose processes..."
    pkill -9 -f "docker-compose.*test-server" 2>/dev/null || true
    
    # Force remove containers
    echo "Removing containers..."
    docker rm -f $(docker ps -a -q --filter "name=test-server") 2>/dev/null || true
    
    # Remove network and volumes
    echo "Removing networks and volumes..."
    docker-compose down -v 2>/dev/null || true
    
    echo -e "${GREEN}Reset complete${NC}"
    ;;
    
  *)
    echo "Test Server Development Helper"
    echo ""
    echo "Usage: $0 {command}"
    echo ""
    echo "Commands:"
    echo "  start           Start services and verify"
    echo "  stop            Stop all services"
    echo "  restart         Restart all services"
    echo "  logs [service]  Follow logs"
    echo "  status          Check service health"
    echo "  shell           Open bash shell in web container"
    echo "  composer <args> Run composer commands in container"
    echo "  clean           Remove containers and volumes"
    echo "  check           Show diagnostic info"
    echo "  reset           Force reset everything (when stuck)"
    echo ""
    ;;
esac
