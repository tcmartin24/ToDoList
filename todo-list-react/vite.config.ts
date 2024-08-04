import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { createProxyMiddleware } from 'http-proxy-middleware';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5275',
        changeOrigin: true,
        secure: false,
        configure: (proxy, options) => {
          proxy.on('proxyReq', (proxyReq, req, res) => {
            let body = [];
            req.on('data', (chunk) => {
              body.push(chunk);
            });
            req.on('end', () => {
              const requestBody = Buffer.concat(body).toString();
            console.log('Request:', {
              method: req.method,
              url: req.url,
              headers: req.headers,
                body: requestBody,
              });
            });
          });
          proxy.on('proxyRes', (proxyRes, req, res) => {
            let body = [];
            proxyRes.on('data', (chunk) => {
              body.push(chunk);
            });
            proxyRes.on('end', () => {
              const responseBody = Buffer.concat(body).toString();
              console.log('Response:', {
                status: proxyRes.statusCode,
                headers: proxyRes.headers,
                body: responseBody,
              });
            });
          });
        },
      },
    },
  },
  logLevel: 'info',
});
