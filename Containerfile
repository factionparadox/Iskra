# Avalon: Universal Blue's base image (Fedora, image-based, no desktop) with the Garden System
# on top. Built on your own machine:  sudo build/make-image  (or, on Avalon itself,
# sudo metamelayer update). Nothing here is compiled: Fedora packages, Mango from a Fedora
# community repository (COPR), llama.cpp's and Piper's own releases (checked by SHA-256).
ARG FEDORA=44
FROM ghcr.io/ublue-os/base-main:${FEDORA}

# the Garden System, Avalon's commands and settings, as they're installed (etc/ and usr/)
COPY desktop/ /
# how the image is made: the package list and the script that installs it
COPY build/image/ /tmp/avalon-build/

RUN /tmp/avalon-build/build.sh && rm -rf /tmp/avalon-build /var/cache/* /var/log/* /var/tmp/*

RUN bootc container lint
