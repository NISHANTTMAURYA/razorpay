import time
from typing import List, Dict, Any, Optional, Callable

class AgentStep:
    """Represents an atomic reasoning or execution step taken by the AI agent."""
    def __init__(self, step_name: str, description: str, tool_name: Optional[str] = None, on_update: Optional[Callable[[Dict[str, Any]], None]] = None):
        self.step_name = step_name
        self.description = description
        self.tool_name = tool_name
        self.status = "RUNNING"
        self.start_time = time.time()
        self.duration_ms = 0
        self.details: Dict[str, Any] = {}
        self._on_update = on_update

    def complete(self, details: Optional[Dict[str, Any]] = None):
        self.status = "COMPLETED"
        self.duration_ms = int((time.time() - self.start_time) * 1000)
        if details:
            self.details = details
        if self._on_update:
            self._on_update({"event": "STEP_COMPLETE", "step": self.to_dict()})

    def fail(self, error_message: str):
        self.status = "FAILED"
        self.duration_ms = int((time.time() - self.start_time) * 1000)
        self.details = {"error": error_message}
        if self._on_update:
            self._on_update({"event": "STEP_FAILED", "step": self.to_dict()})

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
    def __init__(self, callback: Optional[Callable[[Dict[str, Any]], None]] = None):
        self.steps: List[AgentStep] = []
        self.callback = callback

    def start_step(self, step_name: str, description: str, tool_name: Optional[str] = None) -> AgentStep:
        step = AgentStep(step_name=step_name, description=description, tool_name=tool_name, on_update=self.callback)
        self.steps.append(step)
        if self.callback:
            self.callback({"event": "STEP_START", "step": step.to_dict()})
        return step

    def get_steps_data(self) -> List[Dict[str, Any]]:
        return [step.to_dict() for step in self.steps]
