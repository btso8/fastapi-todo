import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.APP_URL?.replace(/\/$/, '') || '';
const TIMEOUT = '5s';

export const options = {
    thresholds: {
        http_req_failed: ['rate==0'],
        http_req_duration: ['p(95)<300'],
    },
    stages: [
        { duration: '1m', target: 5 },
        { duration: '2m', target: 25 },
        { duration: '2m', target: 50 },
        { duration: '1m', target: 0 },
    ],
};

export default function () {
    const r1 = http.get(`${BASE}/health`, { timeout: TIMEOUT });
    check(r1, { 'health 200': (r) => r.status === 200 });

    const q = Math.random() < 0.5 ? '' : '?completed=false';
    const r2 = http.get(`${BASE}/tasks/${q}`, { timeout: TIMEOUT });
    check(r2, { 'list 200': (r) => r.status === 200 });

    sleep(0.2);
}
