from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_fastapi_instrumentator.metrics import (
    default,
    http_requests_total,
    latency,
    requests,
)


def setup_metrics(app):
    inst = Instrumentator(
        should_instrument_requests_inprogress=True,
        excluded_handlers=set(["/metrics", "/health"]),
        should_respect_env_var=True,
    )
    inst.add(default())
    inst.add(http_requests_total())
    inst.add(latency(buckets=(50, 100, 200, 300, 500, 1000, 2000, 5000)))
    inst.add(requests())
    inst.instrument(app).expose(app, include_in_schema=False, should_gzip=True)
