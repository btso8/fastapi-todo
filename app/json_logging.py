import json
import logging
import os
from typing import Any, Dict


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: Dict[str, Any] = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "time": self.formatTime(record, datefmt="%Y-%m-%dT%H:%M:%S%z"),
        }
        for k in ("path", "method", "status_code", "duration_ms"):
            if hasattr(record, k):
                payload[k] = getattr(record, k)
        return json.dumps(payload, ensure_ascii=False)


def setup_dual_logging():
    """Send logs to both console (pretty) and JSON (structured)."""
    level = os.getenv("LOG_LEVEL", "INFO").upper()

    # Console handler (pretty text)
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(
        logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s")
    )

    # JSON handler (structured)
    json_handler = logging.StreamHandler()
    json_handler.setFormatter(JsonFormatter())

    root = logging.getLogger()
    root.handlers = []  # clear existing handlers
    root.setLevel(level)

    root.addHandler(console_handler)
    root.addHandler(json_handler)
