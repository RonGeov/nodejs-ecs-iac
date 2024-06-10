FROM node:12.16-alpine
RUN mkdir node
COPY . ./node
WORKDIR ./node/
RUN npm install express
EXPOSE 3000
CMD node app.js
