from alpine:edge

RUN apk add bird curl php7-cgi php7-mbstring php7-xml unzip lighttpd
RUN apk add php7-json bash php7-tokenizer

ADD crontab.txt /crontab.txt
RUN /usr/bin/crontab /crontab.txt

RUN mkdir -p /etc/bird
ADD bird.default.conf /etc/bird/bird.conf

ADD update_config.sh /update_config.sh
RUN chmod +x /update_config.sh

RUN wget https://github.com/inex/birdseye/releases/download/v1.2.2/birdseye-v1.2.2.tar.bz2 -O /srv/be.tar.bz2
RUN cd /srv && tar jxf /srv/be.tar.bz2 && mv birdseye-v1.2.2 birdseye

RUN cd /srv/birdseye && echo "BIRDC='/srv/birdseye/bin/birdc -2 -s /var/run/bird.ctl'" > .env && echo "CACHE_DRIVER=file" >> .env && chown -R lighttpd:lighttpd /srv/birdseye

ADD lighttpd.conf /etc/lighttpd/lighttpd.conf

RUN mkdir -p /run/lighttpd && chown -R lighttpd:lighttpd /run/lighttpd

ADD entry.sh /entry.sh
RUN chmod +x /entry.sh

ENTRYPOINT /entry.sh
