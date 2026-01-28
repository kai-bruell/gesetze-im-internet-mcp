FROM node:22-alpine

RUN apk add --no-cache \
    curl \
    unzip \
    libxml2-utils \
    xmlstarlet \
    bash

WORKDIR /app

COPY mcp/package*.json ./

RUN npm install --omit=dev

COPY mcp/src/ ./src/

COPY law-xml-downloader.sh ./tools/
COPY get-para.sh ./tools/
COPY table-of-contents.sh ./tools/

RUN chmod +x ./tools/*.sh

RUN mkdir -p /app/laws

# Keep container running for stdio MCP access via exec
CMD ["tail", "-f", "/dev/null"]
