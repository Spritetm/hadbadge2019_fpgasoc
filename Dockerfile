# Dockerfile
# Fetches ECP5 toolchain and sets up working container
# Extra tools for Hackaday Supercon 2019 badge

# Bare bones Debian image
FROM bitnami/minideb:latest

# toolchain parameter, defaults to latest package at time of writing
ARG toolchain='https://github.com/xobs/ecp5-toolchain/releases/download/v1.6.2/ecp5-toolchain-linux_x86_64-v1.6.2.tar.gz'

# Add packages needed to run the toolchain and badge utilities
RUN install_packages wget ca-certificates build-essential bsdmainutils libusb-1.0-0

# Fetch, rename, and extract toolchain package
WORKDIR /
RUN wget $toolchain -O toolchain.tar.gz
RUN mkdir toolchain && tar xzvf toolchain.tar.gz -C toolchain --strip-components=1
RUN rm toolchain.tar.gz

# Add toolchain to path
ENV PATH="/toolchain/bin:${PATH}"

# Create the app directory, where the sourcefiles will be located, and start there
RUN mkdir /app
WORKDIR /app
