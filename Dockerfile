ARG FROM
FROM ${FROM} as builder

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq \
    && apt-get upgrade \
      --yes -qq --no-install-recommends \
    && apt-get install \
      --yes -qq --no-install-recommends \
      build-essential \
      ca-certificates \
      libldap-dev \
      libpq-dev \
      libsasl2-dev \
      libssl-dev \
      libxml2-dev \
      libxmlsec1 \
      libxmlsec1-dev \
      libxmlsec1-openssl \
      libxslt-dev \
      pkg-config \
      python3-dev \
      python3-pip \
      python3-venv \
    && python3 -m venv /opt/netpoint/venv \
    && /opt/netpoint/venv/bin/python3 -m pip install --upgrade \
      pip \
      setuptools \
      wheel

ARG NETBOX_PATH
COPY ${NETBOX_PATH}/requirements.txt requirements-container.txt /
RUN \
    # We compile 'psycopg' in the build process
    sed -i -e '/psycopg/d' /requirements.txt && \
    # Gunicorn is not needed because we use Nginx Unit
    sed -i -e '/gunicorn/d' /requirements.txt && \
    # We need 'social-auth-core[all]' in the Docker image. But if we put it in our own requirements-container.txt
    # we have potential version conflicts and the build will fail.
    # That's why we just replace it in the original requirements.txt.
    sed -i -e 's/social-auth-core\[openidconnect\]/social-auth-core\[all\]/g' /requirements.txt && \
    /opt/netpoint/venv/bin/pip install \
      -r /requirements.txt \
      -r /requirements-container.txt

###
# Main stage
###

ARG FROM
FROM ${FROM} as main

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq \
    && apt-get upgrade \
      --yes -qq --no-install-recommends \
    && apt-get install \
      --yes -qq --no-install-recommends \
      bzip2 \
      ca-certificates \
      curl \
      libldap-common \
      libpq5 \
      libxmlsec1-openssl \
      openssh-client \
      openssl \
      python3 \
      python3-distutils \
      tini \
    && curl --silent --output /usr/share/keyrings/nginx-keyring.gpg \
      https://unit.nginx.org/keys/nginx-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ lunar unit" \
      > /etc/apt/sources.list.d/unit.list \
    && apt-get update -qq \
    && apt-get install \
      --yes -qq --no-install-recommends \
      unit=1.31.1-1~lunar \
      unit-python3.11=1.31.1-1~lunar \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/netpoint/venv /opt/netpoint/venv

ARG NETBOX_PATH
COPY ${NETBOX_PATH} /opt/netpoint
# Copy the modified 'requirements*.txt' files, to have the files actually used during installation
COPY --from=builder /requirements.txt /requirements-container.txt /opt/netpoint/

COPY docker/configuration.docker.py /opt/netpoint/netpoint/netpoint/configuration.py
COPY docker/ldap_config.docker.py /opt/netpoint/netpoint/netpoint/ldap_config.py
COPY docker/docker-entrypoint.sh /opt/netpoint/docker-entrypoint.sh
COPY docker/housekeeping.sh /opt/netpoint/housekeeping.sh
COPY docker/launch-netpoint.sh /opt/netpoint/launch-netpoint.sh
COPY configuration/ /etc/netpoint/config/
COPY docker/nginx-unit.json /etc/unit/

WORKDIR /opt/netpoint/netpoint

# Must set permissions for '/opt/netpoint/netpoint/media' directory
# to g+w so that pictures can be uploaded to netpoint.
RUN mkdir -p static /opt/unit/state/ /opt/unit/tmp/ \
      && chown -R unit:root /opt/unit/ media reports scripts \
      && chmod -R g+w /opt/unit/ media reports scripts \
      && cd /opt/netpoint/ && SECRET_KEY="dummyKeyWithMinimumLength-------------------------" /opt/netpoint/venv/bin/python -m mkdocs build \
          --config-file /opt/netpoint/mkdocs.yml --site-dir /opt/netpoint/netpoint/project-static/docs/ \
      && SECRET_KEY="dummyKeyWithMinimumLength-------------------------" /opt/netpoint/venv/bin/python /opt/netpoint/netpoint/manage.py collectstatic --no-input

ENV LANG=C.utf8 PATH=/opt/netpoint/venv/bin:$PATH
ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD [ "/opt/netpoint/docker-entrypoint.sh", "/opt/netpoint/launch-netpoint.sh" ]

LABEL netpoint.original-tag="" \
      netpoint.git-branch="" \
      netpoint.git-ref="" \
      netpoint.git-url="" \
# See https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
      org.opencontainers.image.created="" \
      org.opencontainers.image.title="NetPoint Docker" \
      org.opencontainers.image.description="A container based distribution of NetPoint, the free and open IPAM and DCIM solution." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.authors="The netpoint-docker contributors." \
      org.opencontainers.image.vendor="The netpoint-docker contributors." \
      org.opencontainers.image.url="https://github.com/khulnasoft/netpoint-docker" \
      org.opencontainers.image.documentation="https://github.com/khulnasoft/netpoint-docker/wiki" \
      org.opencontainers.image.source="https://github.com/khulnasoft/netpoint-docker.git" \
      org.opencontainers.image.revision="" \
      org.opencontainers.image.version=""
