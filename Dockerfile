# Use a lightweight Debian/Ubuntu base image
FROM ubuntu:22.04

# Set environment variables to non-interactive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    iproute2 \
    iputils-ping \
    curl \
    bash \
    sudo \
    && apt-get clean

# Copy local files into the container
COPY setup.sh /app/setup.sh
COPY server.py /app/server.py

# Set working directory
WORKDIR /app

# Ensure setup.sh is executable
RUN chmod +x setup.sh

# Run setup.sh during build-time (optional)
# RUN ./setup.sh

# Expose the ports used by VPN and web server
EXPOSE 80 5000

# Start both VPN setup and web server
CMD ["/bin/bash", "-c", "./setup.sh && python3 server.py"]
