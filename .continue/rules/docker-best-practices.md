---
globs: '["Dockerfile", "**/docker-compose.yml"]'
---

Use specific tags instead of 'latest'. Run containers as non-root user when possible. Use multi-stage builds for smaller images. Include .dockerignore file. Document exposed ports and environment variables.