FROM python:3.8-slim-buster
COPY requirements.txt /
RUN apt update
RUN apt install -y libmagic1
RUN pip install -r /requirements.txt
RUN rm -rf /var/lib/apt/lists/*
