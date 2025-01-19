FROM debian:stable-slim

RUN apt-get update && apt-get install -y ca-certificates

RUN mkdir /app
RUN mkdir /app/frontend

COPY ./azbom /app
COPY ./frontend /app/frontend

EXPOSE 8080

ENV FRONT_FOLDER=/app/frontend

WORKDIR /app

ENTRYPOINT [ "/app/azbom" ]
