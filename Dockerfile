# This extends the base Icingaweb2 container image to include custom libraries for
# other check plugins that are added in later in a volume.

# Build our custom entrypoint binary
# Ref: https://github.com/Icinga/docker-icingaweb2/issues/133
FROM golang:bookworm AS entrypoint

COPY entrypoint /entrypoint

WORKDIR /entrypoint
RUN ["go", "build", "."]

# Grab updated modules for our custom image
FROM composer:lts AS usr-share

RUN ["mkdir", "/usr-share"]
WORKDIR /usr-share

COPY get-mods.sh /
RUN /get-mods.sh snapshot

# Pull our base image in. This instance of the image will be the target to which
# we apply our modifications
FROM icinga/icingaweb2:2.12.6 AS base

# The base image switches to the www-data user, we need to switch to root to do
# our additions.
USER root

# Additional packages installed via apt.
# Keep package names in alphabetical order
RUN apt-get update ;\
	apt-get install --no-install-recommends --no-install-suggests -y \
		curl iputils-ping less vim-tiny wget ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

# Copy in our patched entrypoint binary.
COPY --from=entrypoint /entrypoint/entrypoint /entrypoint

# Copy our earlier downloaded updated modules into the base
COPY --from=usr-share /usr-share/. /usr/share/

# STAGE FOR DEBUGGING STUFF
FROM base AS debug

# Additional packages installed via apt.
# Keep package names in alphabetical order
RUN apt-get update ;\
	apt-get install --no-install-recommends --no-install-suggests -y \
		php-xdebug ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

# Enable XDebug Step Debugging and Develop modes
RUN echo "xdebug.mode=develop,debug\nxdebug.client_host=host.docker.internal" >> /etc/php/8.2/mods-available/xdebug.ini

# Xdebug Port
EXPOSE 9003

# Update the owner of the web files so we can edit them inside the container for debugging
RUN chown -R www-data:www-data /usr/share/icingaweb2

# Switch the user back to www-data so things run cleanly
USER www-data

# STAGE FOR RELEASED VERSION
FROM base AS release

# Switch the user back to www-data so things run cleanly
USER www-data
