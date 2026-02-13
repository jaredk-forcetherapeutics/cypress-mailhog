#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Test Server Status Check"
echo "========================================"
echo ""

# Check Docker Compose services
echo "Docker Compose Services:"
docker-compose ps
echo ""

# Check web service
echo -n "Web Service (http://localhost:3000/cypress-mh-tests/): "
if curl -f -s http://localhost:3000/cypress-mh-tests/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
    echo -e "${YELLOW}  Tip: Check logs with 'docker-compose logs web'${NC}"
fi

# Check MailHog web UI
echo -n "MailHog Web UI (http://localhost:8090/): "
if curl -f -s http://localhost:8090/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
    echo -e "${YELLOW}  Tip: Check logs with 'docker-compose logs mailhog'${NC}"
fi

# Check MailHog API
echo -n "MailHog API (http://localhost:8090/api/v2/messages): "
if curl -f -s http://localhost:8090/api/v2/messages > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Check if vendor directory exists
echo -n "PHP Dependencies (vendor/): "
if docker-compose exec -T web test -d /var/www/html/cypress-mh-tests/vendor 2>/dev/null; then
    echo -e "${GREEN}✓ Installed${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo -e "${YELLOW}  Tip: Run 'docker-compose restart web' to trigger installation${NC}"
fi

echo ""
echo "========================================"

# Exit with error code if any service is down
if curl -f -s http://localhost:3000/cypress-mh-tests/ > /dev/null 2>&1 && \
   curl -f -s http://localhost:8090/ > /dev/null 2>&1; then
    echo -e "${GREEN}All services are healthy!${NC}"
    exit 0
else
    echo -e "${RED}Some services are not healthy${NC}"
    exit 1
fi
