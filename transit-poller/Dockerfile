FROM python:3.11-slim
WORKDIR /app
COPY poller.py .
RUN pip install --no-cache-dir requests psycopg2-binary python-dotenv
CMD ["python", "poller.py"]
