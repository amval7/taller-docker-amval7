# Etapa 1: construir el entorno (no llega a la imagen final)
FROM python:3.14-slim AS build
COPY --from=ghcr.io/astral-sh/uv:0.12.17 /uv /bin/uv
WORKDIR /app
COPY requirements.txt .
RUN uv venv /opt/venv && \
    uv pip install --python /opt/venv/bin/python --no-cache --no-compile -r requirements.txt

# Etapa 2: imagen final
FROM python:3.14-slim
RUN useradd --system --no-create-home appuser
WORKDIR /app
RUN chown appuser:appuser /app
COPY --from=build /opt/venv /opt/venv
COPY --chown=appuser:appuser prestamos ./prestamos
ENV PATH="/opt/venv/bin:$PATH" PYTHONDONTWRITEBYTECODE=1
USER appuser
EXPOSE 9000
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=5 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:9000/salud')"
CMD ["uvicorn", "prestamos.servidor:app", "--host", "0.0.0.0", "--port", "9000"]