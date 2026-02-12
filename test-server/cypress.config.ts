import { defineConfig } from 'cypress'

export default defineConfig({
  allowCypressEnv: false,
  expose: {
    mailHogUrl: 'http://localhost:8090',
  },
  e2e: {
    baseUrl: 'http://localhost:3000/cypress-mh-tests/',
  },
})
