# Stage 1: Build the Godot project
FROM barichello/godot-ci:4.3 AS builder

WORKDIR /app
COPY . .

# Create the export directory
RUN mkdir -p build/web

# Export the project for Web
# The preset name "Web" must match the name in export_presets.cfg
# We export to 'index.html' so it's the default page
RUN godot --headless --verbose --export-release "Web" build/web/index.html

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy the build artifacts from the builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy the custom nginx configuration for COOP/COEP headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
