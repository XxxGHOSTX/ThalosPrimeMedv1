# Thalos Prime - Web Deployment Guide

This document describes the web deployment setup for Thalos Prime.

## Overview

This deployment includes a Flask-based web UI with Docker support and GitHub Actions workflow for container publishing to GitHub Container Registry (GHCR).

## Components

### 1. Flask Web Application (`app.py`)
- Production-ready Flask server with Jinja2 templating
- Background task execution using threading
- RESTful JSON API endpoints
- Web form for task submission
- In-memory CIS core (persists for process lifetime)
- Health check endpoint

### 2. CIS Core Module (`cis/`)
- `cis/core.py`: Cognitive Intelligence System implementation
- Task/intent management
- Background execution support
- Status tracking

### 3. CLI Wrapper (`cli.py`)
- Preserves command-line interface functionality
- Interactive mode
- Single task execution
- Status checking

### 4. Templates (`templates/`)
- `base.html`: Base template with styling
- `index.html`: Home page with task submission form
- `tasks.html`: List all tasks
- `task_detail.html`: Individual task details
- `error.html`: Error page

### 5. Docker Configuration
- `Dockerfile`: Production-ready Python 3.11 slim image
- `docker-compose.yml`: Orchestration configuration
- Non-root user for security
- Health checks
- Port 8000 exposed

### 6. GitHub Actions (`.github/workflows/docker-publish.yml`)
- Automatic builds on push to main branch
- Multi-architecture support (linux/amd64, linux/arm64)
- GHCR authentication using GITHUB_TOKEN
- Image tagging: latest, branch name, commit SHA

### 7. Dependencies (`requirements.txt`)
- Flask 3.0.0
- Gunicorn 21.2.0
- Jinja2 3.1.2

## Quick Start

### Local Development

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the web server:**
   ```bash
   python app.py
   ```

3. **Access the UI:**
   Open http://localhost:8000 in your browser

### Using Docker

1. **Build and run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

2. **Access the UI:**
   Open http://localhost:8000 in your browser

### Using CLI

1. **Execute single task:**
   ```bash
   python cli.py "Analyze the market trends"
   ```

2. **Interactive mode:**
   ```bash
   python cli.py --interactive
   ```

3. **Check status:**
   ```bash
   python cli.py --status
   ```

## API Endpoints

### Web UI Routes
- `GET /` - Home page with task submission form
- `GET /tasks` - List all tasks
- `GET /tasks/<task_id>` - Task details
- `POST /submit` - Submit new task (form)

### JSON API Routes
- `GET /api/status` - Get CIS status
- `GET /api/tasks` - Get all tasks (JSON)
- `POST /api/tasks` - Submit new task (JSON)
- `GET /api/tasks/<task_id>` - Get task details (JSON)
- `GET /health` - Health check

### API Examples

**Submit task via JSON:**
```bash
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"intent": "Hello Thalos Prime"}'
```

**Get all tasks:**
```bash
curl http://localhost:8000/api/tasks
```

**Get specific task:**
```bash
curl http://localhost:8000/api/tasks/<task-id>
```

**Check status:**
```bash
curl http://localhost:8000/api/status
```

## GitHub Container Registry (GHCR)

### Automatic Publishing

When you push to the `main` branch, GitHub Actions will:
1. Build the Docker image
2. Authenticate to GHCR using `GITHUB_TOKEN`
3. Tag the image with:
   - `latest`
   - Branch name (e.g., `main`)
   - Commit SHA (e.g., `main-abc1234`)
4. Push to `ghcr.io/<your-username>/thalos-prime`

### Pulling from GHCR

```bash
# Pull latest
docker pull ghcr.io/<your-username>/thalos-prime:latest

# Run
docker run -p 8000:8000 ghcr.io/<your-username>/thalos-prime:latest
```

### Authentication

The workflow uses `GITHUB_TOKEN` automatically. No manual setup needed.

For local pulls of private images:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin
```

## Configuration

### Environment Variables

- `PORT` - Server port (default: 8000)
- `SECRET_KEY` - Flask secret key (change in production)

### Docker Compose

Edit `docker-compose.yml` to customize:
- Port mapping
- Environment variables
- Restart policy

## Production Deployment

### Using Docker Compose

```bash
# Set production secret key
export SECRET_KEY="your-secure-random-key"

# Run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Using Gunicorn Directly

```bash
# Install dependencies
pip install -r requirements.txt

# Run with Gunicorn
gunicorn --bind 0.0.0.0:8000 --workers 4 --timeout 120 app:app
```

### Using GHCR Image

```bash
docker run -d \
  -p 8000:8000 \
  -e SECRET_KEY="your-secure-random-key" \
  --name thalos-prime \
  ghcr.io/<your-username>/thalos-prime:latest
```

## Architecture Notes

### CIS Core
- Single instance per process
- In-memory task storage
- Thread-safe execution
- Background processing

### Web Application
- Server-side rendering with Jinja2
- Background threads for task execution
- RESTful API for programmatic access
- Responsive UI with gradient styling

### CLI Preservation
- Original CLI functionality maintained
- No modifications to existing CLI files
- New CLI wrapper uses same CIS core

## Security Considerations

1. **Change SECRET_KEY in production**
2. **Use HTTPS in production** (reverse proxy recommended)
3. **Rate limiting** (consider adding in production)
4. **Authentication** (not included, add if needed)
5. **Input validation** (basic validation included)

## Troubleshooting

### Port already in use
```bash
# Change port in docker-compose.yml or:
PORT=8001 python app.py
```

### Container fails to start
```bash
# Check logs
docker-compose logs web

# Rebuild
docker-compose up --build
```

### Cannot pull from GHCR
```bash
# Authenticate
echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin
```

## License

Same license as the main Thalos Prime project (MIT).
