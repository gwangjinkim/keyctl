FROM python:3.11-slim

WORKDIR /app
COPY keyctl .

RUN chmod +x keyctl

CMD ["/app/keyctl", "--help"]