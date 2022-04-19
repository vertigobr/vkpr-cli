FROM alpine:3.15.0

#-----------------------------------------------
# INSTALL DEPENDENCIES
#-----------------------------------------------
RUN apk add --no-cache bash curl && \
  rm -rf /var/cache/apk/*

#-----------------------------------------------
# INSTALL VKPR
#-----------------------------------------------
RUN curl -fsSL https://get.vkpr.net/ | bash && \
  rm -rf /tmp/*

ENV PATH="${PATH}:/root/.vkpr/bin/"
RUN echo 'alias vkpr="rit vkpr"' >> /root/.bashrc
