FROM node:5
MAINTAINER Octoblu, Inc. <docker@octoblu.com>

EXPOSE 80

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm -s install --production
COPY . /usr/src/app/

RUN curl --silent -L https://github.com/coreos/fleet/releases/download/v0.10.2/fleet-v0.10.2-linux-amd64.tar.gz | tar -xz -C /opt/
ENV PATH $PATH:/opt/fleet-v0.10.2-linux-amd64

CMD [ "node", "server.js" ]
