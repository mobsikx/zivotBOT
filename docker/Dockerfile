FROM debian:latest

ONBUILD USER root

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get -y install \
                    apt-utils \
                    procps \
                    vim \
    && apt-get -y install \
                    curl \
                    jq \
                    sqlite3 \
                    tini \
    && curl -sfk https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/google-chrome.deb \
    && apt-get -y --allow-unauthenticated install /tmp/google-chrome.deb \
    && apt-get update \
    && apt-get -y --allow-unauthenticated upgrade \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /tmp/google-chrome.deb

RUN useradd -ms /bin/bash zivotbot \
    && mkdir -p /app/bin \
                /app/db \
                /app/tmp
COPY ./run.sh /app/bin/run.sh
RUN  chmod +x /app/bin/run.sh \
     && chown -R zivotbot:zivotbot /app

WORKDIR /app
USER zivotbot

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/bin/run.sh"]
