FROM quay.io/keycloak/keycloak:latest
ADD ./import  /opt/keycloak/data/import
RUN /opt/keycloak/bin/kc.sh import --dir=/opt/keycloak/data/import/ --override true
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

