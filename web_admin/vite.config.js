import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 8282,
    host: true,
  },
  build: {
    outDir: '../backend/public/admin',
    emptyOutDir: true,
    sourcemap: false,
  },
});
