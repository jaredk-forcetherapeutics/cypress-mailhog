# Test Server Setup

## Overview

This test server runs entirely in Docker containers. **You do NOT need PHP or Composer installed on your host machine.**

## Architecture

- **Web Service:** PHP 8.5 + Apache (serves test pages and handles email sending)
- **MailHog:** SMTP server + web UI for email testing

## Prerequisites

- Docker Desktop for Mac (or Docker Engine on Linux)
- Node.js & Yarn (for Cypress tests only)

## Quick Start

1. **Start the services:**

   ```bash
   cd test-server
   docker-compose up
   ```

2. **Wait for services to be ready** (about 15-30 seconds on first run)

3. **Verify services are accessible:**
   - Test Server: http://localhost:3000/cypress-mh-tests/
   - MailHog UI: http://localhost:8090/

4. **Run Cypress tests:**
   ```bash
   yarn cypress:open
   ```

## First Time Setup

On the first run, the web container will automatically:

1. Install PHP dependencies (PHPMailer) via Composer
2. Start Apache web server
3. Become accessible on port 3000

This may take 15-30 seconds. Check container logs if needed:

```bash
docker-compose logs -f web
```

## Development Workflow

### Using Helper Scripts

The quickest way to manage the test server is using the provided helper scripts:

```bash
# Start services and verify health
./dev.sh start

# Check service status
./dev.sh status

# View logs (all services)
./dev.sh logs

# View logs for specific service
./dev.sh logs web
./dev.sh logs mailhog

# Access container shell
./dev.sh shell

# Run composer commands
./dev.sh composer update
./dev.sh composer show

# Restart services
./dev.sh restart

# Stop services
./dev.sh stop

# Clean up (remove containers and volumes)
./dev.sh clean
```

### Manual Docker Compose Commands

If you prefer using docker-compose directly:

```bash
# Start in foreground (see logs in real-time)
docker-compose up

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart web
```

### Access Container Shell

```bash
docker-compose exec web bash
```

Inside the container, the project is mounted at:

```
/var/www/html/cypress-mh-tests/
```

### Run Composer Commands Inside Container

```bash
# Using helper script
./dev.sh composer install
./dev.sh composer update

# Using docker-compose directly
docker-compose exec web composer install
docker-compose exec web composer update
```

## Troubleshooting

### "Connection refused" on localhost:3000

**Symptoms:** Browser shows "localhost refused to connect" or "connection refused"

**Causes:**

1. Web container failed to start
2. Composer dependencies failed to install
3. macOS-specific Docker issues

**Solutions:**

1. **Check container status:**

   ```bash
   docker-compose ps
   ```

   Both `web` and `mailhog` should show "Up" status.

2. **Check logs for errors:**

   ```bash
   docker-compose logs web
   ```

   Look for errors related to composer or Apache startup.

3. **Ensure port 3000 is available:**

   ```bash
   lsof -i :3000
   ```

   Should show nothing (port is free). If something is using port 3000, stop it or modify the port mapping in docker-compose.yml.

4. **Clean restart:**
   ```bash
   docker-compose down
   docker-compose up --build
   ```

### MailHog accessible but web service not

This indicates the web container is failing to start. Common causes:

1. **Composer install failing** inside container
2. **Port 3000 already in use**
3. **Docker resources exhausted** (CPU/memory)

**Fix:** Check logs and ensure updated docker-compose.yml is being used:

```bash
docker-compose logs web
docker-compose config | grep -A10 "web:"
```

### Composer dependencies not installing

The web container should automatically run `composer install` on startup.

**Manual fix:**

```bash
# Access container
docker-compose exec web bash

# Inside container, navigate to project directory
cd /var/www/html/cypress-mh-tests

# Run composer install
composer install

# Exit and restart
exit
docker-compose restart web
```

### Services hang on startup

**Symptoms:** `docker-compose up` hangs and never completes

**Cause:** Usually due to Docker resource constraints or networking issues

**Fix:**

1. **Check Docker resources:**
   - Open Docker Desktop
   - Go to Settings → Resources
   - Ensure at least 4GB RAM and 2 CPUs allocated

2. **Clean Docker state:**

   ```bash
   docker-compose down
   docker system prune -f
   docker-compose up
   ```

3. **Check for conflicting containers:**
   ```bash
   docker ps -a
   # Remove any old test-server containers
   docker rm $(docker ps -a -q --filter "name=test-server")
   ```

### Vendor directory missing after restart

The `vendor/` directory should persist on your host machine because it's inside the mounted volume.

**Check:**

```bash
ls -la vendor/
```

If missing, restart the container to trigger composer install:

```bash
docker-compose restart web
```

### Permission errors on vendor directory

On Linux, Docker containers may create files with different ownership.

**Fix:**

```bash
# Take ownership of vendor directory
sudo chown -R $USER:$USER vendor/
```

## Platform-Specific Notes

### macOS

- Works with Docker Desktop
- File watching is performant
- No special configuration needed

### Linux

- Should work out of the box
- May need to add your user to the `docker` group:
  ```bash
  sudo usermod -aG docker $USER
  # Log out and back in for changes to take effect
  ```
- File permissions may differ from macOS

### Windows

- Use Docker Desktop with WSL2 backend
- File watching may be slower due to cross-filesystem mounting
- Consider cloning the repo inside WSL2 for better performance

## Architecture Details

### File Structure

```
test-server/
├── docker-compose.yml           # Base service definitions (web + mailhog)
├── docker-compose.ci.yml        # CI override (adds cypress service)
├── README.md                    # This file
├── dev.sh                       # Development helper script
├── verify-services.sh           # Service health check script
├── index.html                   # Test page UI
├── mailer.php                   # Email sending endpoint
├── composer.json                # PHP dependencies
├── composer.lock                # PHP dependency lockfile
├── lib/Mails.php                # Email generation logic
├── cypress/                     # Cypress test specs
└── vendor/                      # PHP dependencies (created at runtime)
```

### Volume Mounts

The web service mounts the current directory into the container at:

```
/var/www/html/cypress-mh-tests/
```

This allows:

- Live code updates without rebuilding
- Composer to install dependencies that persist on host
- Apache to serve files from this directory

### Network Architecture

All services communicate on the `test-server_default` Docker network:

- **Web service:**
  - Internal hostname: `web`
  - External access: http://localhost:3000/cypress-mh-tests/
  - Apache listens on port 80 (mapped to host port 3000)

- **MailHog SMTP:**
  - Internal hostname: `mailhog`
  - SMTP port: 1025 (internal only, not exposed to host)
  - Used by PHP code to send emails

- **MailHog Web UI:**
  - Internal port: 8025
  - External access: http://localhost:8090/
  - API endpoint: http://localhost:8090/api/v2/messages

### Environment Variables

The web service uses these environment variables:

- `PHP_DISPLAY_ERRORS=E_ALL` - Show all PHP errors for debugging
- `WEB_DOCUMENT_ROOT=/var/www/html` - Apache document root

### Health Checks

The web service includes a health check that:

- Tests if Apache is serving the test page
- Runs every 10 seconds
- Allows 30 seconds for initial startup (composer install)
- Retries 3 times before marking as unhealthy

Check health status:

```bash
docker-compose ps
# Look for "healthy" in the STATUS column
```

## Common Tasks

### Update PHP dependencies

```bash
./dev.sh composer update
# Or manually:
docker-compose exec web composer update
```

### Clear MailHog messages

Visit http://localhost:8090/ and click "Delete all messages"

Or via API:

```bash
curl -X DELETE http://localhost:8090/api/v1/messages
```

### View Apache access logs

```bash
docker-compose exec web tail -f /var/log/apache2/access.log
```

### View Apache error logs

```bash
docker-compose exec web tail -f /var/log/apache2/error.log
```

### Test email sending manually

```bash
# Send a test email using the mailer.php endpoint
curl -X POST http://localhost:3000/cypress-mh-tests/mailer.php \
  -d "action=generate-single"

# Check MailHog for the email
open http://localhost:8090/
```

### Run Cypress tests in headless mode

```bash
yarn cypress:run
```

### Run specific Cypress test

```bash
yarn cypress:run --spec "cypress/e2e/your-test.cy.js"
```

## Development Tips

1. **Keep services running:** Leave `docker-compose up` running in one terminal while developing

2. **Watch logs:** Use `./dev.sh logs` to monitor both services simultaneously

3. **Quick verification:** Run `./dev.sh status` after any changes to ensure services are healthy

4. **Clean slate:** If things get weird, run `./dev.sh clean` followed by `./dev.sh start`

5. **Shell access:** Use `./dev.sh shell` to explore the container and debug issues

6. **Composer changes:** After modifying `composer.json`, run `./dev.sh composer update` to apply changes

## Continuous Integration

The `docker-compose.ci.yml` file defines a Cypress service that:

- Builds from the Cypress included image
- Runs Cypress tests in headless mode
- Connects to the web and mailhog services

To run the full test suite in CI mode:

```bash
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up --build --exit-code-from cypress
```

Or use the test script:

```bash
yarn cypress:ci
```

## Additional Resources

- [MailHog Documentation](https://github.com/mailhog/MailHog)
- [Cypress Documentation](https://docs.cypress.io/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PHPMailer Documentation](https://github.com/PHPMailer/PHPMailer)
