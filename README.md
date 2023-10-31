# Dockerizing an Expo React Native Web Application: A Step-By-Step Guide

In this tutorial, we will walk through the process of Dockerizing an Expo React Native web application using a Dockerfile. Docker allows you to package your application and its dependencies into a container, ensuring consistency and portability across different environments.

## 1. Introduction

Docker is a powerful tool for containerization, enabling developers to isolate applications and their dependencies in a standardized environment. Dockerizing a React Native web application can simplify the deployment process and make it easier to manage the application across different environments.

In this tutorial, we will focus on a Dockerfile that is designed for an Expo React Native web application. A sample app located in the `PizzaApp` directory is used to demonstrate the process. Multi-stage builds are used to reduce the size of the final image. The Dockerfile consists of three stages: installing dependencies, building the application, and running it. Three stages are used because the application's dependencies are installed in the first stage, and the build artifacts are copied to the final stage. The second stage is used to build the application, and the third stage is used to run/serve it.

## 2. Stage 1: Installing Dependencies

In the first stage, we install the application's dependencies.

```dockerfile
# Use latest Node.js LTS version as the base image
ARG NODE_VERSION=lts
FROM node:${NODE_VERSION}-bullseye-slim as deps

# Set working directory
WORKDIR /app

# Copy package manifests
COPY ./PizzaApp/package.json ./PizzaApp/yarn.lock ./

# Upgrade yarn to the latest version
RUN yarn set version latest

# Set NODE_ENV in the build stage to avoid installing devDependencies
ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

# Install dependencies
RUN yarn install --frozen-lockfile
```

**Explanation:**

- We use the Node.js LTS version as the base image to ensure compatibility.
- Set the working directory to `/app`.
- Copy the `package.json` and `yarn.lock` files to the container to prepare for dependency installation.
- We upgrade yarn to the latest version for consistent behavior.
- Set the `NODE_ENV` to the value specified in the build stage to avoid installing development dependencies in case of a production build.
- Finally, we use `yarn install` to install the project's dependencies.
- There isn't a need to install `Expo CLI` as it is installed with `expo` in the `package.json` file.

**Alternative:** You can use npm instead of yarn to install dependencies. Replace `yarn install --frozen-lockfile` with `npm install --frozen-lockfile` and `yarn set version latest` with `npm install -g npm@latest`.

## 3. Stage 2: Build

In the second stage, we build the React Native web application.

```dockerfile
FROM node:${NODE_VERSION}-bullseye-slim as build

# Set working directory
WORKDIR /app

# Copy source code and other necessary files
COPY --from=deps /app/node_modules ./node_modules
COPY ./PizzaApp/app ./app
COPY ./PizzaApp/assets ./assets
COPY ./PizzaApp/package.json ./PizzaApp/webpack.config.js ./PizzaApp/App.js ./PizzaApp/app.json ./PizzaApp/babel.config.js ./

# Build the application  -- npx expo export:web
RUN yarn build
```
**Explanation:**

- We use the same Node.js base image as in the previous stage to ensure compatibility.
- Set the working directory to `/app`.
- Copy the application's source code and other necessary files from the dependency installation stage. Instead of copying the entire `/PizzaApp` directory, we copy only the necessary files to reduce the image size.
- Build the application for production using `yarn build` which runs `expo export:web` under the hood.

**Alternative:** Depending on your project, you might use different build commands or tools. Ensure that you replace `yarn build` with the appropriate build command.

## 4. Stage 3: Run

In the final stage, we set up an NGINX server to serve the built application.

```dockerfile
# Use the NGINX_VERSION variable to specify the base image
FROM nginx:${NGINX_VERSION} as run

ARG VERSION=1.0.0
ARG BUILD_DATE

# Label the image
LABEL version="${VERSION}"
LABEL BuildDate="${BUILD_DATE}"

# Copy build artifacts from the previous stage
COPY --from=build /app/web-build /usr/share/nginx/html

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

**Explanation:**

- We use the NGINX base image specified by the `NGINX_VERSION` variable.
- Labels are added to provide information about the image. It is injected during the build process using the `--build-arg` flag which is useful for CI/CD pipelines.
- Copy the build static files from the previous stage to the NGINX container's HTML directory.
- Expose port 80 to make the application accessible.
- Start the NGINX server with `CMD`. `CMD` is used to specify the default command to run when the container is started. In this case, we start the NGINX server with the `daemon off` option to run it in the foreground.

**Alternative:** You can use other web servers like Apache or create a custom server setup depending on your project's requirements.

With this Dockerfile, you can containerize your Expo React Native web application, making it easier to deploy and manage in different environments.

