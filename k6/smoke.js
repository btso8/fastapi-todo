import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = { vus: 1, iterations: 20 };

export default function () {
    const base = __ENV.APP_URL.replace(/\/$/, '');
    const res = http.get(`${base}/health`, { timeout: '5s' });
    check(res, { '200': (r) => r.status === 200 });
    sleep(0.2);
}
