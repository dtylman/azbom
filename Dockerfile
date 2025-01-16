FROM debian:bookworm-slim

RUN mkdir /app
RUN mkdir /app/frontend

COPY ./azbom /app
COPY ./frontend /app/frontend

EXPOSE 8080

ENTRYPOINT [ "/app/azbom" ]
