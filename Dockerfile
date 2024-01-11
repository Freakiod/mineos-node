FROM joshklassen/mineos:base

#download mineos from github
RUN mkdir /usr/games/minecraft

WORKDIR /usr/games/minecraft

RUN git clone --depth=1 https://github.com/joshua-klassen/mineos-node.git .
RUN cp mineos.conf /etc/mineos.conf
RUN chmod +x webui.js mineos_console.js service.js

#build npm deps and clean up apt for image minimalization
RUN apt-get update
RUN apt-get install -y build-essential
RUN npm update
RUN npm install
RUN apt-get remove --purge -y build-essential
RUN apt-get autoremove -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#configure and run supervisor
RUN cp /usr/games/minecraft/init/supervisor_conf /etc/supervisor/conf.d/mineos.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

COPY mineos_cron.sh /etc/cron.d/mineos_cron.sh

EXPOSE 8443 25565-25570
VOLUME /var/games/minecraft

ENV USER_PASSWORD=random_see_log USER_NAME=mc USER_UID=1000 USE_HTTPS=true SERVER_PORT=8443

RUN chmod 777 /usr/games/minecraft/*.sh
RUN chmod 777 /etc/cron.d/mineos_cron.sh

#entrypoint allowing for setting of mc password
ENTRYPOINT ["/usr/games/minecraft/entrypoint.sh"]
