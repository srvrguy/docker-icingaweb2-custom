# This extends the base Icingaweb2 container image to include custom libraries for
# other check plugins that are added in later in a volume.

# Pull our base image in. This instance of the image will be the target to which
# we apply our modifications
FROM icinga/icingaweb2:2.12.2

# The base image switches to the www-data user, we need to switch to root to do
# our additions.
USER root

# Additional packages installed via apt.
# Keep package names in alphabetical order
RUN apt-get update ;\
	apt-get install --no-install-recommends --no-install-suggests -y \
		curl iputils-ping vim-tiny wget ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

# Switch the user back to www-data so things run cleanly
USER www-data