"""
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
            return "I apologize, but I don't have access to real-time weather data. This is a demonstration CIS system."
        
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
