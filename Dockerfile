# Kirara AI v3.2.1 for Railway.
# Upstream publishes no Docker image for v3.x, so we build its official Dockerfile
# recipe from the pinned v3.2.1 release commit, with checksums on every download.
ARG PYTHON_IMAGE=python:3.11.18-slim-bookworm@sha256:a83ba18aef0f865b1a4a611c2cf460fe446f2795673bbb9fe43be570439e3b39

FROM ${PYTHON_IMAGE} AS builder
ARG KIRARA_COMMIT=36249e4a0aa8e3d8930acdfe4e14ec2be6484f63
ARG KIRARA_SHA256=252c4399b95fc9c361b202354b5a618cf56c274771668fc40f48f85fbe7ab28d
ARG WEBUI_VERSION=0.1.0
ARG WEBUI_SHA256=6644959eccc659676633ba0dc6a2f19134a13cf50446868bf5c2c1ad5cd2fcd2
WORKDIR /build
ADD --checksum=sha256:${KIRARA_SHA256} https://github.com/lss233/kirara-ai/archive/${KIRARA_COMMIT}.tar.gz /build/src.tar.gz
ADD --checksum=sha256:${WEBUI_SHA256} https://registry.npmjs.org/kirara-ai-webui/-/kirara-ai-webui-${WEBUI_VERSION}.tgz /build/webui.tgz
RUN mkdir src webui \
 && tar -xzf src.tar.gz -C src --strip-components=1 \
 && tar -xzf webui.tgz -C webui \
 && pip install --no-cache-dir build==1.2.2.post1 \
 && cd src && python -m build --wheel --outdir /build/dist

FROM ${PYTHON_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    MALLOC_ARENA_MAX=2 \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    PORT=8080
# Same runtime packages as upstream's Dockerfile (wkhtmltopdf and ffmpeg are used by plugins).
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends wkhtmltopdf ffmpeg libmagic1 curl \
 && rm -r /var/lib/apt/lists/*
COPY --from=builder /build/src/data/fonts/sarasa-mono-sc-regular.ttf /usr/share/fonts/
COPY --from=builder /build/dist/*.whl /tmp/wheel/
RUN pip install --no-cache-dir /tmp/wheel/*.whl && rm -r /tmp/wheel
WORKDIR /app
COPY --from=builder /build/webui/package/dist/ /app/web/
COPY --from=builder /build/src/data/ /tmp/data/
COPY start.sh configure.py /app/railway/
RUN chmod +x /app/railway/start.sh
EXPOSE 8080
CMD ["/app/railway/start.sh"]
