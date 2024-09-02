# Stage 1: Build the game using SteamCMD
FROM steamcmd/steamcmd:alpine AS builder

# Argument to specify the game version
ARG GAME_VERSION=public

# Install the game using SteamCMD
RUN steamcmd \
    +force_install_dir /app \
    +login anonymous \
    +app_update 1690800 \
    -beta $GAME_VERSION \
    validate +quit

# Stage 2: Set up the runtime environment
FROM redhat/ubi9-minimal

# Arguments for user and group IDs
ARG PUID=1000
ARG PGID=1000

# Set working directory
WORKDIR /app

# Create a non-root user
RUN microdnf install -y shadow-utils
RUN groupadd -g ${PGID} visitor && \
    useradd -l -u ${PUID} -g visitor visitor

# Copy game files from the builder stage
COPY --from=builder /app /app

# Copy custom scripts into the application directory
COPY scripts/* /app/

#
RUN mkdir /app/config/
RUN ln -s /app/config /home/visitor/.config/Epic

#
RUN chown visitor:visitor /app

# Switch to the non-root user
USER visitor

# Expose all used port by satisfactory server
EXPOSE 7777/udp
EXPOSE 15000/udp
EXPOSE 15777/udp

#
VOLUME "/app/config"
VOLUME "/app/Engine/Saved"
VOLUME "/app/FactoryGame/Saved"
VOLUME "/app/FactoryGame/Intermediate/DatasmithContentTemp"

# Set the default command
ENTRYPOINT [ "sh", "/app/start.sh" ]
