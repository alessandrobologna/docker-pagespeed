FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY start /start
RUN chmod +x /start
CMD ["nginx", "-g", "daemon off;"]
ENTRYPOINT ["/start"]