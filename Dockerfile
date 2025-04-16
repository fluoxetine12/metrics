# Base image
FROM node:20-bookworm-slim

# Copy repository
COPY . /metrics
WORKDIR /metrics

# # Setup
# RUN chmod +x /metrics/source/app/action/index.mjs \
#   # Install latest chrome dev package, fonts to support major charsets and skip chromium download on puppeteer install
#   # Based on https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md#running-puppeteer-in-docker
#   && apt-get update \
#   && apt-get install -y wget gnupg ca-certificates libgconf-2-4 \
#   && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
#   && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
#   && apt-get update \
#   && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libx11-xcb1 libxtst6 lsb-release --no-install-recommends \
#   # Install deno for miscellaneous scripts
#   && apt-get install -y curl unzip \
#   && curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=/usr/local sh \
#   # Install ruby to support github licensed gem
#   && apt-get install -y ruby-full git g++ cmake pkg-config libssl-dev \
#   && gem install licensed \
#   # Install python for node-gyp
#   && apt-get install -y python3 \
#   # Clean apt/lists
#   && rm -rf /var/lib/apt/lists/* \
#   # Install node modules and rebuild indexes
#   && npm ci \
#   && npm run build

# Base setup and package manager update
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    libgconf-2-4 \
    curl \
    unzip \
    lsb-release \
 && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (using recommended GPG key method)
RUN apt-get update && apt-get install -y wget gnupg \
 && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg \
 && sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list' \
 && apt-get update \
 && apt-get install -y google-chrome-stable \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-freefont-ttf \
    libxss1 \
    libx11-xcb1 \
    libxtst6 \
    --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

# Install Deno
RUN curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=/usr/local sh

# Install Ruby, build tools, and licensed gem
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full \
    git \
    g++ \
    cmake \
    pkg-config \
    libssl-dev \
    python3 \
 && gem install licensed \
 && rm -rf /var/lib/apt/lists/*

# Make script executable (should happen after COPYing the source code)
# Assuming source code is copied before this step
RUN chmod +x /metrics/source/app/action/index.mjs

# Install Node dependencies (assuming package.json and package-lock.json are copied)
# WORKDIR /metrics/source/app/action  or similar might be needed before this
RUN npm ci

# Build the application
RUN npm run build


# Environment variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_BROWSER_PATH "google-chrome-stable"

# Execute GitHub action
ENTRYPOINT node /metrics/source/app/action/index.mjs
