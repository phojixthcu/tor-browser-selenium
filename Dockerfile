FROM python:3.7.3-slim

ENV PYTHONUNBUFFERED 1
ENV BUILD_PACKAGES build-essential libpq-dev

RUN set -ex \
    && apt-get update \
    && apt-get install -y libpq5 curl unzip xz-utils gnupg2 xvfb x11vnc libgtk-3-0 libdbus-glib-1-2 tor \  
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /usr/src/app
WORKDIR /usr/src/app

# DOWNLOAD TOR BROWSER
RUN \
    VERSION=9.0a3 && \
    curl -SL -o /usr/src/app/tor.tar.xz \
      https://dist.torproject.org/torbrowser/${VERSION}/tor-browser-linux64-${VERSION}_en-US.tar.xz && \
    tar -xvf /usr/src/app/tor.tar.xz && \
    mv /usr/src/app/tor-browser_en-US /usr/bin/tbb && \
    rm -f /usr/src/app/tor.tar.xz* && \
    chmod -R 777 /usr/bin/tbb

# DOWNLOAD GECKODRIVER
RUN \
    VERSION=0.24.0 && \
    curl -SL -o /usr/src/app/geckodriver.tar.gz \
      https://github.com/mozilla/geckodriver/releases/download/v{$VERSION}/geckodriver-v{$VERSION}-linux64.tar.gz && \
    tar -xvzf /usr/src/app/geckodriver.tar.gz && \
    mv /usr/src/app/geckodriver /usr/bin/tbb/Browser && \
    rm -f /usr/src/app/geckodriver.tar.gz && \
    chmod -R 777 /usr/bin/tbb

RUN touch geckodriver.log

RUN addgroup --system django && adduser --system --ingroup django django
RUN mkdir -p /var/log/leprechaunwormhole \
    && chown -R django:django /var/log/leprechaunwormhole

COPY requirements-dev.txt /usr/src/app/
COPY requirements-travis.txt /usr/src/app/

RUN set -ex \
    && apt-get -y update \
    && apt-get install -y vim \
    && apt-get install -y $BUILD_PACKAGES \
    && pip install --no-cache-dir -r /usr/src/app/requirements-dev.txt \
    && pip install --no-cache-dir -r /usr/src/app/requirements-travis.txt \
    && apt-get autoremove -y $BUILD_PACKAGES \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /usr/src/app/Downloads

RUN pip install --no-cache-dir selenium selenium-wire

ENV LD_LIBRARY_PATH=/usr/src/app/tor/Browser/TorBrowser/Tor/
RUN chmod -R 777 /usr/bin/tbb
ENV NO_XVFB=1
RUN chmod 777 /tmp
RUN mkdir /usr/bin/tbb/Browser/.seleniumwire && chmod 777 /usr/bin/tbb/Browser/.seleniumwire
RUN chmod -R 777 /usr/src/app/

COPY --chown=django:django . /usr/src/app
RUN chown django:django geckodriver.log

USER django

VOLUME ["/srv/"]

EXPOSE 8089
