# Use latest Node.js LTS version as base image
ARG NODE_VERSION=lts

# Set a default value for NGINX_VERSION
ARG NGINX_VERSION=alpine

# Stage 1: Install dependencies
FROM node:${NODE_VERSION}-bullseye-slim as deps

# Set working directory
WORKDIR /app

# Copy package manifests
COPY ./PizzaApp/package.json ./PizzaApp/yarn.lock ./

# Upgrade yarn to latest version
RUN yarn set version latest

# Set NODE_ENV in build stage to avoid installing devDependencies
ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

# Install dependencies
RUN yarn install --frozen-lockfile


# Stage 2: Build
FROM node:${NODE_VERSION}-bullseye-slim as build

# Set working directory
WORKDIR /app

# Copy source code
COPY --from=deps /app/node_modules ./node_modules
COPY ./PizzaApp/app ./app
COPY ./PizzaApp/assets ./assets
COPY ./PizzaApp/package.json ./PizzaApp/webpack.config.js ./PizzaApp/App.js ./PizzaApp/app.json ./PizzaApp/babel.config.js ./

# Build for production -- npx expo export:web
RUN yarn build  

# Stage 3: RUN
# Use the NGINX_VERSION variable to specify the base image
FROM nginx:${NGINX_VERSION} as run

ARG VERSION=1.0.0
ARG BUILD_DATE

# Label image
LABEL version="${VERSION}"
LABEL BuildDate="${BUILD_DATE}"

# Copy build artifacts from previous stage
COPY --from=build /app/web-build /usr/share/nginx/html

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
