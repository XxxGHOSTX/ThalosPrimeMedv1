"""
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
