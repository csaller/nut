FROM debian:bookworm-slim

# PyQt5 comes from Debian because PyPI has no Linux arm64 wheels for it.
# The build tools are for the requirements that only ship source dists (pycurl, zstandard).
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl libcurl4-openssl-dev libssl-dev libusb-1.0-0 \
        python3 python3-dev python3-pip python3-pyqt5 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./

RUN grep -iv '^pyqt5' requirements.txt > /tmp/requirements.txt && \
    pip install --no-cache-dir --break-system-packages -r /tmp/requirements.txt

ARG USER=nut
ARG GROUP=nut
ARG TARGETARCH
RUN addgroup --gid 1000 $USER && \
    adduser --uid 1000 --ingroup $GROUP --home /home/$USER --shell /bin/sh --disabled-password --gecos "" $USER && \
    chown $USER:$GROUP /app && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.6.0/fixuid-0.6.0-linux-${TARGETARCH}.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

# nut.py chdirs to /app and writes its lock file and titledb there, so the user must own /app.
COPY --chown=$USER:$GROUP . ./

USER $USER:$GROUP

ENTRYPOINT ["fixuid"]

CMD ["python3", "/app/nut_gui.py"]
