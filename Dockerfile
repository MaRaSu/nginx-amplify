FROM bitnami/nginx:1.24.0-debian-11-r0

### Change user to perform privileged actions
USER 0

# Install required system packages and dependencies
RUN apt-get update && apt-get install -y gosu wget curl python3

# Install Amplify Agent manually
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y curl gnupg1 procps lsb-release ca-certificates debian-archive-keyring \
    && curl https://nginx.org/keys/nginx_signing.key | gpg1 --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://packages.amplify.nginx.com/py3/debian/ $(lsb_release -cs) amplify-agent" > /etc/apt/sources.list.d/nginx-amplify.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y nginx-amplify-agent \
    && apt-mark hold nginx-amplify-agent \
    && apt-get remove --purge --auto-remove -y curl gnupg1 \
    && rm -f /etc/apt/sources.list.d/nginx-amplify.list \
    && rm -f /usr/share/keyrings/nginx-archive-keyring.gpg \
    && rm -rf /var/lib/apt/lists/*

# Configure the agent with custom API key
RUN api_key="e89c924bab356b5d2021bb1db6a9dcf2" && \
sed "s/api_key.*$/api_key = ${api_key}/" \
/etc/amplify-agent/agent.conf.default > \
/etc/amplify-agent/agent.conf

# Modify the agent configuration file
RUN sed -i 's|#configfile = /etc/nginx/nginx.conf|configfile = /opt/bitnami/nginx/conf/nginx.conf|' /etc/amplify-agent/agent.conf
RUN sed -i 's|#stub_status = /nginx_status|stub_status = http://127.0.0.1:8081/status|' /etc/amplify-agent/agent.conf
RUN sed -i 's|#user = nginx|user = 1001|' /etc/amplify-agent/agent.conf
RUN useradd -r -u 1001 -g root 1001

# Activate nginx stub_status module - not needed since in k8s custom serverBlock
#COPY ./stub_status.conf /opt/bitnami/nginx/conf/bitnami/stub_status.conf
#RUN cat /opt/bitnami/nginx/conf/bitnami/stub_status.conf >> /opt/bitnami/nginx/conf/bitnami/bitnami.conf
#RUN chmod 644 /opt/bitnami/nginx/conf/bitnami/bitnami.conf
#RUN rm /opt/bitnami/nginx/conf/bitnami/stub_status.conf

# Add Bitnami environment variables to the agent init script
RUN sed -i '/^PATH/a . /opt/bitnami/scripts/nginx-env.sh' /etc/init.d/amplify-agent
RUN sed -i '1s|#!.*|#!/bin/bash|' /etc/init.d/amplify-agent

# Add custom entrypoint script to start Amplify Agent before Nginx
COPY ./amplify-entrypoint.sh /opt/bitnami/scripts/nginx/amplify-entrypoint.sh
RUN chmod +x /opt/bitnami/scripts/nginx/amplify-entrypoint.sh

# Comment out user directive in nginx.conf to avoid Agent getting confused
RUN sed -i 's/^user/#user/' /opt/bitnami/nginx/conf/nginx.conf

# Keep the nginx logs inside the container
RUN unlink /opt/bitnami/nginx/logs/access.log \
    && unlink /opt/bitnami/nginx/logs/error.log \
    && touch /opt/bitnami/nginx/logs/access.log \
    && touch /opt/bitnami/nginx/logs/error.log \
    && chown root /opt/bitnami/nginx/logs/*log \
    && chmod 666 /opt/bitnami/nginx/logs/*log

ENV APP_VERSION="1.24.0" \
    BITNAMI_APP_NAME="nginx" \
    NGINX_HTTPS_PORT_NUMBER="" \
    NGINX_HTTP_PORT_NUMBER="" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/nginx/sbin:$PATH"

ENV AMPLIFY_IMAGENAME="registry.finomena.fi/c/amplify-nginx"

EXPOSE 8081

WORKDIR /app
# Start as root to start Amplify Agent before downgrading to non-root user 1001
USER 0
ENTRYPOINT [ "/opt/bitnami/scripts/nginx/amplify-entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/nginx/run.sh" ]


