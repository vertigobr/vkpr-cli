FROM alpine:3.15.0
ARG version
#-----------------------------------------------
# INSTALL DEPENDENCIES
#-----------------------------------------------
RUN apk add --no-cache bash curl openssl && \
  rm -rf /var/cache/apk/*

#-----------------------------------------------
# INSTALL VKPR
#-----------------------------------------------
RUN curl -fsSL https://get.vkpr.net/ | bash && \
  rm -rf /tmp/*

ENV PATH="${PATH}:/root/.vkpr/bin/"
RUN rit update repo --name="vkpr-cli" --version=$version
RUN echo 'alias vkpr="rit vkpr"' >> /root/.bashrc
