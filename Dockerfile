FROM python:3.8
ENV PYTHONUNBUFFERED=1

WORKDIR /yc_backend

COPY requirements.txt /yc_backend
RUN pip install -r requirements.txt

COPY . /yc_backend

RUN chmod +x /yc_backend/entrypoint.sh
ENTRYPOINT ["/bin/sh", "/yc_backend/entrypoint.sh"]
