from alpine:edge

RUN apk add --no-cache bird

RUN apk add --no-cache curl

ADD crontab.txt /crontab.txt
RUN /usr/bin/crontab /crontab.txt

RUN mkdir -p /etc/bird
ADD bird.default.conf /etc/bird/bird.conf

ADD update_config.sh /update_config.sh
RUN chmod +x /update_config.sh

ADD entry.sh /entry.sh
RUN chmod +x /entry.sh

ENTRYPOINT /entry.sh
