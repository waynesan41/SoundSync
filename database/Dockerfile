FROM mongo:7.0

COPY mongo-keyfile /etc/mongo-keyfile
RUN chown mongodb:mongodb /etc/mongo-keyfile && chmod 400 /etc/mongo-keyfile