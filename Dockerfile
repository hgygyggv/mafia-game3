# Written by blitz.cloud for this project. It is yours now: blitz.cloud
# builds from it as it is, and you can change it like any other file.
FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY server.js ./
COPY index-8.html ./
COPY README-FA.txt ./
RUN chown -R 1000:1000 /app
ENV PORT=8080
EXPOSE 8080
USER 1000:1000
CMD ["node", "server.js"]
