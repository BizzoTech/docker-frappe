FROM bizzotech/frappe-base
MAINTAINER Emad Shaaban <emad@bizzotech.com>

# Update
ENV FRAPPE_USER frappe
ENV BENCH_BRANCH master
ENV FRAPPE_BRANCH v8.2.7

RUN addgroup -S $FRAPPE_USER && \
    adduser -D -G $FRAPPE_USER $FRAPPE_USER && \
    echo 'frappe ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers

USER $FRAPPE_USER
WORKDIR /home/$FRAPPE_USER
RUN git clone -b $BENCH_BRANCH --depth 1 https://github.com/$FRAPPE_USER/bench bench-repo && \
    sudo pip install -e /home/$FRAPPE_USER/bench-repo --no-cache-dir && \
    mkdir -p frappe-bench && cd frappe-bench && \
    mkdir -p apps logs sites/localhost config && \
    bench setup env && \
    sudo bench setup sudoers $FRAPPE_USER && \
    bench setup socketio && \
    bench get-app frappe https://github.com/frappe/frappe --branch $FRAPPE_BRANCH

ENV DOCKERIZE_VERSION v0.2.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && sudo tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && rm *.tar.gz

ADD ./config/ /tmp/config
ADD ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN cp /tmp/config/site_config.json /home/$FRAPPE_USER/frappe-bench/sites/common_site_config.json && \
    cp /tmp/config/site_config.json /home/$FRAPPE_USER/frappe-bench/sites/localhost/site_config.json && \
    cp /tmp/config/apps.txt /home/$FRAPPE_USER/frappe-bench/sites/apps.txt && \
    sudo chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME /home/$FRAPPE_USER/frappe-bench/logs
VOLUME /home/$FRAPPE_USER/frappe-bench/sites/localhost

WORKDIR /home/$FRAPPE_USER/frappe-bench

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["app"]
