
# using nginx, which is a lightweight web server
FROM nginx:alpine

# copy the content of the local 'html' folder to the default nginx public folder
COPY index.html /usr/share/nginx/html

