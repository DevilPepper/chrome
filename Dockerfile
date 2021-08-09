# Based on this: https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker

FROM node:16-slim as build-chrome
LABEL org.opencontainers.image.source https://github.com/SupaStuff/chrome

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
                    ca-certificates \
                    curl \
                    git \
                    gnupg \
                    vim \
 && rm -rf /var/lib/apt/lists/*

RUN curl -s https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
 && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
                    google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

# Until I figure out how to get the sandbox to work in Docker container
ENV RESUME_PUPPETEER_NO_SANDBOX=true

RUN npm install -g npm@7.19.1


FROM build-chrome as test-chrome

RUN set -ex
RUN node --version
RUN git --version
RUN google-chrome --version


FROM build-chrome as build-jupyter

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
                    python3 \
                    python3-pip \
                    libgl1-mesa-glx \
 && python3 -m pip install --upgrade \
                           pip \
                           setuptools \
                           wheel \
 && python3 -m pip install jupyter \
 && npm install -g tslab \
 && tslab install \
 && rm -rf /var/lib/apt/lists/*


FROM build-jupyter as test-jupyter

RUN set -ex
RUN python3 --version
RUN jupyter --version
RUN tslab install --version


FROM build-jupyter as build-vscode

ARG USERNAME=vscode

RUN usermod --login $USERNAME --move-home --home /home/$USERNAME $(id -nu 1000) \
 && mkdir -p /home/$USERNAME/workspace/node_modules \
        /home/$USERNAME/.local \
        /home/$USERNAME/.vscode-server/extensions \
        /home/$USERNAME/.vscode-server-insiders/extensions \
 && chown -R $USERNAME \
        /home/$USERNAME/.local \
        /home/$USERNAME/workspace \
        /home/$USERNAME/.vscode-server \
        /home/$USERNAME/.vscode-server-insiders

USER $USERNAME
WORKDIR /home/$USERNAME


FROM build-vscode as test-vscode

RUN set -ex
RUN [ $(whoami) = "vscode" ]
RUN [ $(id -u) = 1000 ]