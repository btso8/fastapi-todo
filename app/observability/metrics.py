from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_fastapi_instrumentator.metrics import default, latency
from prometheus_fastapi_instrumentator.metrics import requests as reqs_inprogress


def setup_metrics(app):
    inst = Instrumentator(
        should_instrument_requests_inprogress=True,
        excluded_handlers={"/metrics", "/health"},
        should_respect_env_var=True,
    )
    inst.add(default())
    inst.add(latency(buckets=(50, 100, 200, 300, 500, 1000, 2000, 5000)))
    inst.add(reqs_inprogress())
    inst.instrument(app).expose(app, include_in_schema=False, should_gzip=True)
    return inst
