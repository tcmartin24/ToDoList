import {defineConfig, loadEnv} from 'vite';
import react from '@vitejs/plugin-react';
import { ProxyOptions } from 'vite';
import * as http from 'http';
import * as HttpProxy from 'http-proxy';

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  const useProxy = env.VITE_USE_PROXY !== 'false' && command === 'serve';

  return {
    plugins: [react()],
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: './setupTests.ts',
      css: true,
      coverage: {
        provider: 'istanbul',
        reporter: ['text', 'json', 'html'],
      },
    },
    server: useProxy ? {
      proxy: {
        '/api': {
          target: env.VITE_API_BASE_URL || 'http://localhost:8080',
          changeOrigin: true,
          secure: false,
          configure: (proxy, options) => {
            configureProxy(proxy as HttpProxy, options);
          }
        }
      },
    } : {},
    logLevel: 'info',
    // define: {
    //   'import.meta.env.VITE_API_BASE_URL': JSON.stringify(env.VITE_API_BASE_URL),
    // },
  }
});


function configureProxy(proxy: HttpProxy, options: ProxyOptions): void {
  proxy.on('proxyReq', (proxyReq: http.ClientRequest, req: http.IncomingMessage, res: http.ServerResponse) => {
    handleProxyRequest(proxyReq, req, res, options);
  });
  proxy.on('proxyRes', (proxyRes: http.IncomingMessage, req: http.IncomingMessage, res: http.ServerResponse) => {
    handleProxyResponse(proxyRes, req, res);
  });
}

function handleProxyRequest(proxyReq: http.ClientRequest, req: http.IncomingMessage, res: http.ServerResponse, options: ProxyOptions): void {
  let body: Buffer[] = [];
  req.on('data', (chunk: Buffer) => {
    body.push(chunk);
  });
  req.on('end', () => {
    const requestBody = Buffer.concat(body).toString();
    logRequest(req, requestBody);
  });
}

function handleProxyResponse(proxyRes: http.IncomingMessage, req: http.IncomingMessage, res: http.ServerResponse): void {
  let body: Buffer[] = [];
  proxyRes.on('data', (chunk: Buffer) => {
    body.push(chunk);
  });
  proxyRes.on('end', () => {
    const responseBody = Buffer.concat(body).toString();
    logResponse(proxyRes, responseBody);
  });
}

function logRequest(req: http.IncomingMessage, body: string): void {
  console.log('Request:', {
    method: req.method,
    url: req.url,
    headers: req.headers,
    body: body,
  });
}

function logResponse(proxyRes: http.IncomingMessage, body: string): void {
  console.log('Response:', {
    status: proxyRes.statusCode,
    headers: proxyRes.headers,
    body: body,
  });
}