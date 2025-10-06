import http from 'k6/http';
import { check, sleep } from 'k6';

// Avoid optional chaining; do simple truthy check
const rawBase = (__ENV.APP_URL || '').toString();
const BASE = rawBase.replace(/\/$/, ''); // strip trailing slash
if (!BASE) {
    throw new Error('APP_URL env var is required, e.g. https://your-app.example');
}

export const options = {
    stages: [
        { duration: '30s', target: 10 },
        { duration: '60s', target: 20 },
        { duration: '30s', target: 0 },
    ],
    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<300'],
    },
};

export default function () {
    const res = http.get(`${BASE}/healthz`, { timeout: '5s' });
    check(res, { 'status is 200': (r) => r.status === 200 });
    sleep(1);
}
