FROM python:3.9-slim-buster
ARG APP_GID=1000
ARG APP_UID=1000
ENV ACME_HOME=/home/acme/acme.sh

COPY entrypoint.py /
COPY runner.sh /

# prepare environment
RUN apt update && apt install -y curl \
    && groupadd -g $APP_GID acme \
    && useradd -m -u $APP_UID -g $APP_GID acme \
    && chmod 755 /entrypoint.py \
    && chmod 755 /runner.sh \
    && mkdir /acme.sh && curl -L https://github.com/acmesh-official/acme.sh/archive/master.tar.gz \
        | tar -xvzf - -C /acme.sh --strip 1 && chmod 755 /acme.sh/acme.sh \
    && pip install --no-cache-dir schedule

USER acme
ENTRYPOINT ["/usr/bin/env", "python", "/entrypoint.py"]
