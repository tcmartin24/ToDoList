/// <reference types="vite/client" />

interface ImportMetaEnv {
    readonly VITE_API_BASE_URL: string
    readonly VITE_APP_NAME: string
    // Add other environment variables here
}

interface ImportMeta {
    readonly env: ImportMetaEnv
}