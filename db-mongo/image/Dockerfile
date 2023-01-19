FROM node:latest

WORKDIR /app/

COPY ./package.json /app/

RUN npm i

ARG MONGO_DB_URL
ENV MONGO_DB_URL ${MONGO_DB_URL}

COPY ./src /app/src
COPY ./init.sh /app/init.sh

RUN chmod 700 /app/init.sh

ENTRYPOINT [ "./init.sh" ]