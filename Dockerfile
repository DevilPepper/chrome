# Based on this: https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker

FROM node:19-slim as build-chrome
LABEL org.opencontainers.image.source https://github.com/SupaStuff/chrome

ARG USERNAME=vscode

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
                    ca-certificates \
                    curl \
                    git \
                    gnupg \
                    less \
                    libgl1-mesa-glx \
                    ssh-client \
                    vim \
 && rm -rf /var/lib/apt/lists/*

RUN curl -s https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
 && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
                    google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@7.21.0


FROM build-chrome as test-chrome

RUN set -ex
RUN node --version
RUN git --version
RUN google-chrome --version


FROM build-chrome as build-python

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
                    python3 \
                    python3-pip \
 && python3 -m pip install --upgrade \
                           pip \
                           setuptools \
                           wheel \
 && rm -rf /var/lib/apt/lists/*


FROM build-python as test-python

RUN set -ex
RUN python3 --version


FROM build-python as build-jupyter

RUN python3 -m pip install jupyter \
 && npm install -g tslab \
 && tslab install


FROM build-jupyter as test-jupyter

RUN set -ex
RUN jupyter --version
RUN tslab install --version


FROM build-chrome as build-vscode

RUN usermod --login $USERNAME --move-home --home /home/$USERNAME $(id -nu 1000) \
 && mkdir -p /home/$USERNAME/workspace/node_modules \
        /home/$USERNAME/.vscode-server/extensions \
        /home/$USERNAME/.vscode-server-insiders/extensions \
 && chown -R $USERNAME \
        /home/$USERNAME/workspace \
        /home/$USERNAME/.vscode-server \
        /home/$USERNAME/.vscode-server-insiders

WORKDIR /home/$USERNAME

FROM build-vscode as test-vscode

RUN set -ex
RUN [ $(id -u vscode) = 1000 ]


FROM build-python as build-python-vscode

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

WORKDIR /home/$USERNAME

FROM build-python-vscode as test-python-vscode

RUN set -ex
RUN [ $(id -u vscode) = 1000 ]


FROM build-jupyter as build-jupyter-vscode

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

WORKDIR /home/$USERNAME

FROM build-jupyter-vscode as test-jupyter-vscode

RUN set -ex
RUN [ $(id -u vscode) = 1000 ]
