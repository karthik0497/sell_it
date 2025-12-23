FROM python:3.9-slim

WORKDIR /app

# Install system dependencies (if any)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*



# Install dependencies
COPY infra/docker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .


# Set environment variables
ENV PythonUNBUFFERED=1

# Command to run the application (placeholder, update based on actual app entrypoint)
# Assuming a FastAPI app or similar, but for now just keeping it alive or running a script
CMD ["python", "main.py"] 
