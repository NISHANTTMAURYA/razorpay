import time
from typing import List, Dict, Any, Optional

class AgentStep:
    """Represents an atomic reasoning or execution step taken by the AI agent."""
    def __init__(self, step_name: str, description: str, tool_name: Optional[str] = None):
        self.step_name = step_name
        self.description = description
        self.tool_name = tool_name
        self.status = "RUNNING"
        self.start_time = time.time()
        self.duration_ms = 0
        self.details: Dict[str, Any] = {}

    def complete(self, details: Optional[Dict[str, Any]] = None):
        self.status = "COMPLETED"
        self.duration_ms = int((time.time() - self.start_time) * 1000)
        if details:
            self.details = details

    def fail(self, error_message: str):
        self.status = "FAILED"
        self.duration_ms = int((time.time() - self.start_time) * 1000)
        self.details = {"error": error_message}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "step_name": self.step_name,
            "description": self.description,
            "tool_name": self.tool_name,
            "status": self.status,
            "duration_ms": self.duration_ms,
            "details": self.details,
        }

class AgentExecutionTracer:
    """Collects and streams execution steps during LangGraph agent execution."""
    def __init__(self):
        self.steps: List[AgentStep] = []

    def start_step(self, step_name: str, description: str, tool_name: Optional[str] = None) -> AgentStep:
        step = AgentStep(step_name=step_name, description=description, tool_name=tool_name)
        self.steps.append(step)
        return step

    def get_steps_data(self) -> List[Dict[str, Any]]:
        return [step.to_dict() for step in self.steps]
