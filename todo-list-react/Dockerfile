# Build stage
FROM node:20 as build

WORKDIR /app

COPY package*.json ./
COPY package-lock.json ./
RUN npm install

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html

# Copy a custom nginx configuration if needed
# COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
ENV VITE_APP_MODE=local

CMD ["nginx", "-g", "daemon off;"]