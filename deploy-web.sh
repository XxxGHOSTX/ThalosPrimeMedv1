#!/usr/bin/env bash
# ============================================================================
# Thalos Prime Web Deployment Setup Script
# ============================================================================
# This script prepares a full web deployment for Thalos Prime using Flask,
# Docker, and GitHub Actions workflow for GHCR publishing.
#
# It will:
# - Clone or reuse the repository
# - Create a web-deploy branch
# - Add web deployment components (never overwriting existing files)
# - Commit changes
# - Generate patch and bundle artifacts
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/XxxGHOSTX/ThalosPrime-v1.0.git"
REPO_NAME="ThalosPrime-v1.0"
BRANCH_NAME="web-deploy"
MAIN_BRANCH="main"

# Track what we add
ADDED_FILES=()
SKIPPED_FILES=()

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}===================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Function to add file only if it doesn't exist
add_file_if_not_exists() {
    local filepath="$1"
    local content="$2"
    
    if [[ -f "$filepath" ]]; then
        print_warning "Skipped (already exists): $filepath"
        SKIPPED_FILES+=("$filepath")
        return 1
    else
        echo "$content" > "$filepath"
        ADDED_FILES+=("$filepath")
        print_success "Added: $filepath"
        return 0
    fi
}

# ============================================================================
# Main Script
# ============================================================================

print_header "Thalos Prime Web Deployment Setup"

# Change to parent directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

print_info "Working directory: $PARENT_DIR"

# Step 1: Clone or reuse repository
print_header "Step 1: Repository Setup"

cd "$PARENT_DIR"

if [[ -d "$REPO_NAME" ]]; then
    print_info "Repository already exists, reusing: $REPO_NAME"
    cd "$REPO_NAME"
else
    print_info "Cloning repository: $REPO_URL"
    git clone "$REPO_URL"
    cd "$REPO_NAME"
    print_success "Repository cloned"
fi

# Step 2: Checkout main and create web-deploy branch
print_header "Step 2: Branch Setup"

# Configure git if not configured
if ! git config user.email >/dev/null 2>&1; then
    git config user.email "deploy@thalosprime.local"
    git config user.name "Thalos Prime Deploy"
    print_info "Configured git user"
fi

# Fetch latest changes
git fetch origin 2>/dev/null || true

# Check if we're already on web-deploy
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]]; then
    # Checkout main branch
    if git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1; then
        git checkout "$MAIN_BRANCH"
        print_success "Checked out $MAIN_BRANCH branch"
    elif git rev-parse --verify "origin/$MAIN_BRANCH" >/dev/null 2>&1; then
        git checkout -b "$MAIN_BRANCH" "origin/$MAIN_BRANCH"
        print_success "Checked out $MAIN_BRANCH branch from origin"
    else
        print_warning "Main branch not found, using current branch"
    fi
    
    # Create or checkout web-deploy branch
    if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
        git checkout "$BRANCH_NAME"
        print_info "Switched to existing $BRANCH_NAME branch"
    else
        git checkout -b "$BRANCH_NAME"
        print_success "Created new branch: $BRANCH_NAME"
    fi
else
    print_info "Already on $BRANCH_NAME branch"
fi

# Step 3: Add web deployment components
print_header "Step 3: Adding Web Deployment Components"

# ============================================================================
# 3.1: Create CIS Core Module
# ============================================================================
print_info "Creating CIS core module..."

mkdir -p cis

add_file_if_not_exists "cis/__init__.py" 'from .core import CISCore

__all__ = ["CISCore"]
'

add_file_if_not_exists "cis/core.py" '"""
CIS Core - Cognitive Intelligence System
This is a simulated CIS core that demonstrates the architecture.
"""
import time
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum


class TaskStatus(Enum):
    """Task execution status"""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class Task:
    """Represents a task/intent in the CIS"""
    id: str
    intent: str
    status: TaskStatus
    created_at: datetime
    updated_at: datetime
    result: Optional[str] = None
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class CISCore:
    """
    Cognitive Intelligence System Core
    
    This class maintains the CIS state in memory for the lifetime of the process.
    It handles task/intent submissions and executions.
    """
    
    def __init__(self):
        """Initialize the CIS core"""
        self.tasks: Dict[str, Task] = {}
        self.initialized_at = datetime.now()
        print(f"[CIS Core] Initialized at {self.initialized_at}")
    
    def submit_task(self, intent: str, metadata: Optional[Dict[str, Any]] = None) -> Task:
        """
        Submit a new task/intent to the CIS
        
        Args:
            intent: The task intent/description
            metadata: Optional metadata for the task
            
        Returns:
            Task: The created task object
        """
        task_id = str(uuid.uuid4())
        now = datetime.now()
        
        task = Task(
            id=task_id,
            intent=intent,
            status=TaskStatus.PENDING,
            created_at=now,
            updated_at=now,
            metadata=metadata or {}
        )
        
        self.tasks[task_id] = task
        print(f"[CIS Core] Task submitted: {task_id} - {intent}")
        
        return task
    
    def execute_task(self, task_id: str) -> Task:
        """
        Execute a task by its ID
        
        Args:
            task_id: The task ID to execute
            
        Returns:
            Task: The updated task object
            
        Raises:
            ValueError: If task not found
        """
        if task_id not in self.tasks:
            raise ValueError(f"Task not found: {task_id}")
        
        task = self.tasks[task_id]
        task.status = TaskStatus.RUNNING
        task.updated_at = datetime.now()
        
        print(f"[CIS Core] Executing task: {task_id}")
        
        try:
            # Simulate task processing
            time.sleep(1)  # Simulate work
            
            # Generate result based on intent
            result = self._process_intent(task.intent)
            
            task.result = result
            task.status = TaskStatus.COMPLETED
            task.updated_at = datetime.now()
            
            print(f"[CIS Core] Task completed: {task_id}")
            
        except Exception as e:
            task.status = TaskStatus.FAILED
            task.error = str(e)
            task.updated_at = datetime.now()
            print(f"[CIS Core] Task failed: {task_id} - {e}")
        
        return task
    
    def _process_intent(self, intent: str) -> str:
        """
        Process an intent and generate a result
        
        Args:
            intent: The task intent
            
        Returns:
            str: The result of processing
        """
        # Simple intent processing simulation
        intent_lower = intent.lower()
        
        if "hello" in intent_lower or "hi" in intent_lower:
            return "Hello! I am Thalos Prime, a cognitive intelligence system. How can I assist you?"
        
        elif "weather" in intent_lower:
            return "I apologize, but I don'\''t have access to real-time weather data. This is a demonstration CIS system."
        
        elif "calculate" in intent_lower or "compute" in intent_lower:
            return "I have processed your calculation request. This is a demonstration response."
        
        elif "analyze" in intent_lower:
            return f"Analysis complete: I have analyzed your request \"{intent}\" and generated this demonstration response."
        
        else:
            return f"I have processed your request: \"{intent}\". This is a demonstration of the CIS processing capability."
    
    def get_task(self, task_id: str) -> Optional[Task]:
        """Get a task by ID"""
        return self.tasks.get(task_id)
    
    def get_all_tasks(self) -> List[Task]:
        """Get all tasks, sorted by creation time (newest first)"""
        return sorted(
            self.tasks.values(),
            key=lambda t: t.created_at,
            reverse=True
        )
    
    def get_task_count(self) -> int:
        """Get total number of tasks"""
        return len(self.tasks)
    
    def get_status(self) -> Dict[str, Any]:
        """Get CIS status"""
        status_counts = {status.value: 0 for status in TaskStatus}
        for task in self.tasks.values():
            status_counts[task.status.value] += 1
        
        return {
            "initialized_at": self.initialized_at.isoformat(),
            "total_tasks": len(self.tasks),
            "status_breakdown": status_counts
        }
'

# ============================================================================
# 3.2: Create Flask Web Application
# ============================================================================
print_info "Creating Flask web application..."

add_file_if_not_exists "app.py" '"""
Thalos Prime Web Application
Flask-based web UI with background task execution
"""
import os
import threading
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for
from cis import CISCore

# Initialize Flask app
app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "dev-secret-key-change-in-production")

# Initialize CIS Core (kept in memory for process lifetime)
cis_core = CISCore()

# Background task execution lock
task_lock = threading.Lock()


def execute_task_background(task_id: str):
    """Execute a task in the background"""
    with task_lock:
        try:
            cis_core.execute_task(task_id)
        except Exception as e:
            print(f"[Web App] Error executing task {task_id}: {e}")


@app.route("/")
def index():
    """Main page - show task submission form and recent tasks"""
    tasks = cis_core.get_all_tasks()[:10]  # Show last 10 tasks
    status = cis_core.get_status()
    return render_template("index.html", tasks=tasks, status=status)


@app.route("/tasks")
def tasks_list():
    """List all tasks"""
    tasks = cis_core.get_all_tasks()
    return render_template("tasks.html", tasks=tasks)


@app.route("/tasks/<task_id>")
def task_detail(task_id):
    """Show details of a specific task"""
    task = cis_core.get_task(task_id)
    if not task:
        return render_template("error.html", message="Task not found"), 404
    return render_template("task_detail.html", task=task)


@app.route("/submit", methods=["POST"])
def submit_task():
    """Submit a new task via web form"""
    intent = request.form.get("intent", "").strip()
    
    if not intent:
        return render_template("error.html", message="Intent cannot be empty"), 400
    
    # Submit task
    task = cis_core.submit_task(intent)
    
    # Execute in background thread
    thread = threading.Thread(target=execute_task_background, args=(task.id,))
    thread.daemon = True
    thread.start()
    
    # Redirect to task detail page
    return redirect(url_for("task_detail", task_id=task.id))


@app.route("/api/status")
def api_status():
    """API endpoint: Get CIS status"""
    return jsonify(cis_core.get_status())


@app.route("/api/tasks", methods=["GET", "POST"])
def api_tasks():
    """API endpoint: Get all tasks or submit new task"""
    if request.method == "GET":
        tasks = cis_core.get_all_tasks()
        return jsonify({
            "tasks": [
                {
                    "id": task.id,
                    "intent": task.intent,
                    "status": task.status.value,
                    "created_at": task.created_at.isoformat(),
                    "updated_at": task.updated_at.isoformat(),
                    "result": task.result,
                    "error": task.error
                }
                for task in tasks
            ]
        })
    
    elif request.method == "POST":
        data = request.get_json()
        if not data or "intent" not in data:
            return jsonify({"error": "Intent is required"}), 400
        
        intent = data["intent"].strip()
        if not intent:
            return jsonify({"error": "Intent cannot be empty"}), 400
        
        # Submit task
        task = cis_core.submit_task(intent, metadata=data.get("metadata"))
        
        # Execute in background thread
        thread = threading.Thread(target=execute_task_background, args=(task.id,))
        thread.daemon = True
        thread.start()
        
        return jsonify({
            "id": task.id,
            "intent": task.intent,
            "status": task.status.value,
            "created_at": task.created_at.isoformat(),
            "updated_at": task.updated_at.isoformat()
        }), 201


@app.route("/api/tasks/<task_id>")
def api_task_detail(task_id):
    """API endpoint: Get task details"""
    task = cis_core.get_task(task_id)
    
    if not task:
        return jsonify({"error": "Task not found"}), 404
    
    return jsonify({
        "id": task.id,
        "intent": task.intent,
        "status": task.status.value,
        "created_at": task.created_at.isoformat(),
        "updated_at": task.updated_at.isoformat(),
        "result": task.result,
        "error": task.error,
        "metadata": task.metadata
    })


@app.route("/health")
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    })


if __name__ == "__main__":
    # Development server
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port, debug=True)
'

# ============================================================================
# 3.3: Create Jinja Templates
# ============================================================================
print_info "Creating Jinja templates..."

mkdir -p templates

add_file_if_not_exists "templates/base.html" '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Thalos Prime{% endblock %}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            overflow: hidden;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }
        
        nav {
            background: #f8f9fa;
            padding: 15px 30px;
            border-bottom: 1px solid #dee2e6;
        }
        
        nav a {
            color: #667eea;
            text-decoration: none;
            margin-right: 20px;
            font-weight: 500;
        }
        
        nav a:hover {
            color: #764ba2;
        }
        
        main {
            padding: 30px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.85rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-pending { background: #ffc107; color: #000; }
        .status-running { background: #17a2b8; color: #fff; }
        .status-completed { background: #28a745; color: #fff; }
        .status-failed { background: #dc3545; color: #fff; }
        
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 1rem;
            cursor: pointer;
            text-decoration: none;
            transition: background 0.3s;
        }
        
        .btn:hover {
            background: #764ba2;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #495057;
        }
        
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #ced4da;
            border-radius: 5px;
            font-size: 1rem;
            font-family: inherit;
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 100px;
        }
        
        footer {
            background: #f8f9fa;
            padding: 20px 30px;
            text-align: center;
            color: #6c757d;
            border-top: 1px solid #dee2e6;
        }
    </style>
    {% block extra_head %}{% endblock %}
</head>
<body>
    <div class="container">
        <header>
            <h1>🧠 Thalos Prime</h1>
            <p>Cognitive Intelligence System</p>
        </header>
        
        <nav>
            <a href="/">Home</a>
            <a href="/tasks">All Tasks</a>
            <a href="/api/status" target="_blank">API Status</a>
        </nav>
        
        <main>
            {% block content %}{% endblock %}
        </main>
        
        <footer>
            <p>Thalos Prime v1.0 - Web Deployment Edition</p>
        </footer>
    </div>
</body>
</html>
'

add_file_if_not_exists "templates/index.html" '{% extends "base.html" %}

{% block title %}Home - Thalos Prime{% endblock %}

{% block content %}
<div style="margin-bottom: 40px;">
    <h2>Submit Task / Intent</h2>
    <form method="POST" action="/submit" style="margin-top: 20px;">
        <div class="form-group">
            <label for="intent">Enter your task or intent:</label>
            <textarea 
                id="intent" 
                name="intent" 
                placeholder="e.g., Analyze the latest market trends, Calculate the optimal route, Hello Thalos Prime"
                required
            ></textarea>
        </div>
        <button type="submit" class="btn">Submit Task</button>
    </form>
</div>

<div style="margin-bottom: 40px;">
    <h2>System Status</h2>
    <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin-top: 15px;">
        <p><strong>Initialized:</strong> {{ status.initialized_at }}</p>
        <p><strong>Total Tasks:</strong> {{ status.total_tasks }}</p>
        <p><strong>Status Breakdown:</strong></p>
        <ul style="margin-left: 20px; margin-top: 10px;">
            <li>Pending: {{ status.status_breakdown.pending }}</li>
            <li>Running: {{ status.status_breakdown.running }}</li>
            <li>Completed: {{ status.status_breakdown.completed }}</li>
            <li>Failed: {{ status.status_breakdown.failed }}</li>
        </ul>
    </div>
</div>

<div>
    <h2>Recent Tasks</h2>
    {% if tasks %}
        <div style="margin-top: 20px;">
            {% for task in tasks %}
            <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 15px; border-left: 4px solid #667eea;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <strong>{{ task.intent[:80] }}{% if task.intent|length > 80 %}...{% endif %}</strong>
                    <span class="status-badge status-{{ task.status.value }}">{{ task.status.value }}</span>
                </div>
                <p style="font-size: 0.9rem; color: #6c757d; margin-bottom: 10px;">
                    <strong>ID:</strong> {{ task.id }}<br>
                    <strong>Created:</strong> {{ task.created_at.strftime("%Y-%m-%d %H:%M:%S") }}
                </p>
                <a href="/tasks/{{ task.id }}" class="btn" style="padding: 8px 16px; font-size: 0.9rem;">View Details</a>
            </div>
            {% endfor %}
        </div>
        <a href="/tasks" class="btn" style="margin-top: 20px;">View All Tasks</a>
    {% else %}
        <p style="margin-top: 20px; color: #6c757d;">No tasks yet. Submit your first task above!</p>
    {% endif %}
</div>
{% endblock %}
'

add_file_if_not_exists "templates/tasks.html" '{% extends "base.html" %}

{% block title %}All Tasks - Thalos Prime{% endblock %}

{% block content %}
<div style="margin-bottom: 20px;">
    <h2>All Tasks</h2>
    <a href="/" class="btn" style="margin-top: 15px;">← Back to Home</a>
</div>

{% if tasks %}
    <div style="margin-top: 30px;">
        {% for task in tasks %}
        <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 15px; border-left: 4px solid #667eea;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                <strong>{{ task.intent[:100] }}{% if task.intent|length > 100 %}...{% endif %}</strong>
                <span class="status-badge status-{{ task.status.value }}">{{ task.status.value }}</span>
            </div>
            <p style="font-size: 0.9rem; color: #6c757d; margin-bottom: 10px;">
                <strong>ID:</strong> {{ task.id }}<br>
                <strong>Created:</strong> {{ task.created_at.strftime("%Y-%m-%d %H:%M:%S") }}<br>
                <strong>Updated:</strong> {{ task.updated_at.strftime("%Y-%m-%d %H:%M:%S") }}
            </p>
            {% if task.result %}
                <p style="margin-bottom: 10px;"><strong>Result:</strong> {{ task.result[:150] }}{% if task.result|length > 150 %}...{% endif %}</p>
            {% endif %}
            {% if task.error %}
                <p style="color: #dc3545; margin-bottom: 10px;"><strong>Error:</strong> {{ task.error }}</p>
            {% endif %}
            <a href="/tasks/{{ task.id }}" class="btn" style="padding: 8px 16px; font-size: 0.9rem;">View Full Details</a>
        </div>
        {% endfor %}
    </div>
{% else %}
    <p style="margin-top: 30px; color: #6c757d;">No tasks yet.</p>
{% endif %}
{% endblock %}
'

add_file_if_not_exists "templates/task_detail.html" '{% extends "base.html" %}

{% block title %}Task {{ task.id }} - Thalos Prime{% endblock %}

{% block content %}
<div style="margin-bottom: 30px;">
    <h2>Task Details</h2>
    <a href="/tasks" class="btn" style="margin-top: 15px; margin-right: 10px;">← Back to Tasks</a>
    <a href="/" class="btn" style="margin-top: 15px;">← Home</a>
</div>

<div style="background: #f8f9fa; padding: 25px; border-radius: 5px; border-left: 4px solid #667eea;">
    <div style="margin-bottom: 20px;">
        <h3 style="display: inline-block; margin-right: 15px;">Status:</h3>
        <span class="status-badge status-{{ task.status.value }}">{{ task.status.value }}</span>
    </div>
    
    <div style="margin-bottom: 20px;">
        <h3>Task ID</h3>
        <p style="font-family: monospace; background: white; padding: 10px; border-radius: 3px; margin-top: 5px;">{{ task.id }}</p>
    </div>
    
    <div style="margin-bottom: 20px;">
        <h3>Intent</h3>
        <p style="background: white; padding: 15px; border-radius: 3px; margin-top: 5px; white-space: pre-wrap;">{{ task.intent }}</p>
    </div>
    
    {% if task.result %}
    <div style="margin-bottom: 20px;">
        <h3>Result</h3>
        <p style="background: white; padding: 15px; border-radius: 3px; margin-top: 5px; white-space: pre-wrap;">{{ task.result }}</p>
    </div>
    {% endif %}
    
    {% if task.error %}
    <div style="margin-bottom: 20px;">
        <h3>Error</h3>
        <p style="background: #fff5f5; color: #dc3545; padding: 15px; border-radius: 3px; margin-top: 5px; white-space: pre-wrap;">{{ task.error }}</p>
    </div>
    {% endif %}
    
    <div style="margin-bottom: 20px;">
        <h3>Timeline</h3>
        <p><strong>Created:</strong> {{ task.created_at.strftime("%Y-%m-%d %H:%M:%S") }}</p>
        <p><strong>Updated:</strong> {{ task.updated_at.strftime("%Y-%m-%d %H:%M:%S") }}</p>
    </div>
    
    {% if task.metadata %}
    <div style="margin-bottom: 20px;">
        <h3>Metadata</h3>
        <pre style="background: white; padding: 15px; border-radius: 3px; margin-top: 5px; overflow-x: auto;">{{ task.metadata }}</pre>
    </div>
    {% endif %}
</div>

{% if task.status.value == "pending" or task.status.value == "running" %}
<div style="margin-top: 30px; padding: 15px; background: #fff3cd; border-radius: 5px;">
    <p><strong>Note:</strong> This task is currently {{ task.status.value }}. Refresh the page to see updates.</p>
    <button onclick="location.reload()" class="btn" style="margin-top: 10px;">Refresh Page</button>
</div>
{% endif %}
{% endblock %}
'

add_file_if_not_exists "templates/error.html" '{% extends "base.html" %}

{% block title %}Error - Thalos Prime{% endblock %}

{% block content %}
<div style="background: #fff5f5; border-left: 4px solid #dc3545; padding: 25px; border-radius: 5px;">
    <h2 style="color: #dc3545;">Error</h2>
    <p style="margin-top: 15px; font-size: 1.1rem;">{{ message }}</p>
</div>

<div style="margin-top: 30px;">
    <a href="/" class="btn">← Back to Home</a>
</div>
{% endblock %}
'

# ============================================================================
# 3.4: Create CLI Wrapper
# ============================================================================
print_info "Creating CLI wrapper..."

add_file_if_not_exists "cli.py" '#!/usr/bin/env python3
"""
Thalos Prime CLI
Command-line interface wrapper that preserves CLI functionality
"""
import argparse
import sys
from cis import CISCore


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Thalos Prime - Cognitive Intelligence System CLI"
    )
    
    parser.add_argument(
        "intent",
        nargs="*",
        help="Task intent to execute"
    )
    
    parser.add_argument(
        "--status",
        action="store_true",
        help="Show CIS status"
    )
    
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Enter interactive mode"
    )
    
    args = parser.parse_args()
    
    # Initialize CIS Core
    cis = CISCore()
    
    if args.status:
        # Show status
        status = cis.get_status()
        print("\n=== Thalos Prime Status ===")
        print(f"Initialized: {status['\''initialized_at'\'']}")
        print(f"Total Tasks: {status['\''total_tasks'\'']}")
        print("\nStatus Breakdown:")
        for status_name, count in status['\''status_breakdown'\''].items():
            print(f"  {status_name}: {count}")
        return 0
    
    elif args.interactive:
        # Interactive mode
        print("=== Thalos Prime Interactive Mode ===")
        print("Enter tasks/intents (type '\''exit'\'' to quit)\n")
        
        while True:
            try:
                intent = input("Intent> ").strip()
                
                if not intent:
                    continue
                
                if intent.lower() in ["exit", "quit", "q"]:
                    print("Goodbye!")
                    break
                
                # Submit and execute task
                task = cis.submit_task(intent)
                print(f"\nTask ID: {task.id}")
                print("Executing...")
                
                task = cis.execute_task(task.id)
                
                if task.status.value == "completed":
                    print(f"\n✓ Completed")
                    print(f"Result: {task.result}\n")
                else:
                    print(f"\n✗ Failed")
                    print(f"Error: {task.error}\n")
                    
            except KeyboardInterrupt:
                print("\nInterrupted. Goodbye!")
                break
            except EOFError:
                print("\nGoodbye!")
                break
        
        return 0
    
    elif args.intent:
        # Single task execution
        intent = " ".join(args.intent)
        
        print(f"Submitting task: {intent}")
        
        # Submit and execute task
        task = cis.submit_task(intent)
        print(f"Task ID: {task.id}")
        print("Executing...")
        
        task = cis.execute_task(task.id)
        
        if task.status.value == "completed":
            print(f"\n✓ Task completed successfully")
            print(f"Result: {task.result}")
            return 0
        else:
            print(f"\n✗ Task failed")
            print(f"Error: {task.error}")
            return 1
    
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
'

# ============================================================================
# 3.5: Create requirements.txt
# ============================================================================
print_info "Creating requirements.txt..."

add_file_if_not_exists "requirements.txt" 'Flask==3.0.0
Werkzeug==3.0.1
gunicorn==21.2.0
Jinja2==3.1.2
MarkupSafe==2.1.3
'

# ============================================================================
# 3.6: Create Dockerfile
# ============================================================================
print_info "Creating Dockerfile..."

add_file_if_not_exists "Dockerfile" '# Thalos Prime Web Deployment - Production Dockerfile
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY cis/ ./cis/
COPY templates/ ./templates/
COPY app.py .
COPY cli.py .

# Create non-root user
RUN useradd -m -u 1000 thalos && chown -R thalos:thalos /app
USER thalos

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('\''http://localhost:8000/health'\'').read()"

# Run with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "app:app"]
'

# ============================================================================
# 3.7: Create docker-compose.yml
# ============================================================================
print_info "Creating docker-compose.yml..."

add_file_if_not_exists "docker-compose.yml" 'version: '\''3.8'\''

services:
  web:
    build: .
    container_name: thalos-prime-web
    ports:
      - "8000:8000"
    environment:
      - PORT=8000
      - SECRET_KEY=${SECRET_KEY:-dev-secret-key-change-in-production}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('\''http://localhost:8000/health'\'').read()"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
'

# ============================================================================
# 3.8: Create GitHub Actions Workflow
# ============================================================================
print_info "Creating GitHub Actions workflow..."

mkdir -p .github/workflows

add_file_if_not_exists ".github/workflows/docker-publish.yml" 'name: Docker Build and Push to GHCR

on:
  push:
    branches:
      - web-deploy
    tags:
      - '\''v*'\''
  pull_request:
    branches:
      - web-deploy

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/thalos-prime

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: Log in to GitHub Container Registry
        if: github.event_name != '\''pull_request'\''
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Extract metadata (tags, labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
            
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != '\''pull_request'\'' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          
      - name: Image digest
        run: echo "Image pushed with digest ${{ steps.build-and-push.outputs.digest }}"
'

# ============================================================================
# 3.9: Create Web Deployment README
# ============================================================================
print_info "Creating web deployment README..."

add_file_if_not_exists "WEB_DEPLOYMENT_README.md" '# Thalos Prime - Web Deployment Guide

This document describes the web deployment setup for Thalos Prime.

## Overview

This deployment adds a Flask-based web UI with Docker support and GitHub Actions workflow for container publishing to GitHub Container Registry (GHCR).

## Components Added

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
- Automatic builds on push to web-deploy branch
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
  -d '\''{"intent": "Hello Thalos Prime"}'\''
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

When you push to the `web-deploy` branch, GitHub Actions will:
1. Build the Docker image
2. Authenticate to GHCR using `GITHUB_TOKEN`
3. Tag the image with:
   - `latest`
   - Branch name (e.g., `web-deploy`)
   - Commit SHA (e.g., `web-deploy-abc1234`)
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
'

# ============================================================================
# 3.10: Create .dockerignore
# ============================================================================
print_info "Creating .dockerignore..."

add_file_if_not_exists ".dockerignore" '.git
.gitignore
.github
*.md
README.md
WEB_DEPLOYMENT_README.md
docker-compose.yml
*.pyc
__pycache__
.pytest_cache
.venv
venv/
env/
node_modules/
*.log
.DS_Store
'

# ============================================================================
# 3.11: Create .gitignore additions
# ============================================================================
print_info "Checking .gitignore..."

if [[ ! -f ".gitignore" ]]; then
    add_file_if_not_exists ".gitignore" '# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
.venv
pip-log.txt
pip-delete-this-directory.txt
.pytest_cache/

# Flask
instance/
.webassets-cache

# Environment
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker
*.log
'
fi

# Step 4: Stage new files
print_header "Step 4: Staging New Files"

if [[ ${#ADDED_FILES[@]} -eq 0 ]]; then
    print_warning "No new files were added. Nothing to commit."
    exit 0
fi

print_info "Staging ${#ADDED_FILES[@]} new files..."

for file in "${ADDED_FILES[@]}"; do
    git add "$file"
done

print_success "Files staged"

# Step 5: Commit changes
print_header "Step 5: Committing Changes"

COMMIT_MESSAGE="Add web deployment (Flask UI, Docker, docker-compose, GHCR workflow)

This commit adds a comprehensive web deployment setup:
- Flask web application with Jinja2 templates
- CIS core module with task/intent management
- CLI wrapper preserving CLI functionality
- Production-ready Dockerfile (Python 3.11 slim, port 8000)
- docker-compose.yml for easy orchestration
- GitHub Actions workflow for GHCR publishing
- Web deployment documentation

Components added: ${#ADDED_FILES[@]} files
No existing files were modified."

git commit -m "$COMMIT_MESSAGE"

print_success "Changes committed to $BRANCH_NAME branch"

# Step 6: Generate artifacts
print_header "Step 6: Generating Artifacts"

cd "$PARENT_DIR"

# Generate patch
print_info "Generating patch file..."
cd "$REPO_NAME"
git format-patch -1 HEAD --stdout > "../web-deploy.patch"
cd "$PARENT_DIR"
print_success "Patch created: $PARENT_DIR/web-deploy.patch"

# Generate bundle
print_info "Generating bundle file..."
cd "$REPO_NAME"
git bundle create "../web-deploy.bundle" "$BRANCH_NAME"
cd "$PARENT_DIR"
print_success "Bundle created: $PARENT_DIR/web-deploy.bundle"

# Step 7: Summary
print_header "Summary"

echo ""
print_success "Web deployment setup complete!"
echo ""
echo "Files added: ${#ADDED_FILES[@]}"
for file in "${ADDED_FILES[@]}"; do
    echo "  ✓ $file"
done

if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
    echo ""
    echo "Files skipped (already exist): ${#SKIPPED_FILES[@]}"
    for file in "${SKIPPED_FILES[@]}"; do
        echo "  ⚠ $file"
    done
fi

echo ""
print_info "Artifacts created:"
echo "  📦 $PARENT_DIR/web-deploy.patch"
echo "  📦 $PARENT_DIR/web-deploy.bundle"

# Final instructions
print_header "Next Steps"

cat << '\''EOF'\''

✅ WHAT WAS DONE:

1. Created web-deploy branch (or used existing)
2. Added Flask web application with Jinja2 templates
3. Added CIS core module for task/intent processing
4. Added CLI wrapper to preserve CLI functionality
5. Added production Dockerfile (Python 3.11 slim, port 8000)
6. Added docker-compose.yml
7. Added requirements.txt
8. Added GitHub Actions workflow for GHCR publishing
9. Added web deployment README
10. Committed all changes to web-deploy branch
11. Generated patch and bundle files

📝 IMPORTANT NOTES:

- No existing files were overwritten
- CLI functionality is preserved via cli.py wrapper
- Web UI reuses CIS components from cis/ module
- All components use port 8000 consistently
- GHCR workflow uses GITHUB_TOKEN for authentication

🚀 HOW TO USE:

1. Test locally:
   cd ThalosPrime-v1.0
   pip install -r requirements.txt
   python app.py
   # Visit http://localhost:8000

2. Test with Docker:
   cd ThalosPrime-v1.0
   docker-compose up --build
   # Visit http://localhost:8000

3. Test CLI:
   cd ThalosPrime-v1.0
   python cli.py "Hello Thalos Prime"
   python cli.py --interactive

4. Push to GitHub (when ready):
   cd ThalosPrime-v1.0
   git push origin web-deploy

5. After pushing, GitHub Actions will:
   - Build Docker image for multiple architectures
   - Authenticate to GHCR using GITHUB_TOKEN
   - Push images tagged as:
     * ghcr.io/<your-username>/thalos-prime:latest
     * ghcr.io/<your-username>/thalos-prime:web-deploy
     * ghcr.io/<your-username>/thalos-prime:web-deploy-<commit-sha>

6. Open a Pull Request:
   - Go to https://github.com/XxxGHOSTX/ThalosPrime-v1.0
   - Click "Compare & pull request" for web-deploy branch
   - Add description and create PR

7. Apply patch elsewhere (optional):
   cd /path/to/other/repo
   git am < /path/to/web-deploy.patch

8. Use bundle elsewhere (optional):
   git clone /path/to/web-deploy.bundle -b web-deploy

📚 DOCUMENTATION:

See WEB_DEPLOYMENT_README.md for:
- Detailed component descriptions
- API documentation
- Deployment guides
- Configuration options
- Troubleshooting

🔒 SECURITY REMINDERS:

- Change SECRET_KEY in production
- Use HTTPS in production (reverse proxy recommended)
- GHCR images are public by default (configure visibility in settings)
- Consider adding authentication for production use

EOF

print_header "Script Complete"
print_success "All tasks completed successfully!"

exit 0
'