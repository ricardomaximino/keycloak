FROM quay.io/keycloak/keycloak:17.0.1 as builder

ENV KC_METRICS_ENABLED=true
ENV KC_DB=mysql
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:17.0.1
COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
WORKDIR /opt/keycloak
COPY ./certs/brasatech-server.p12 conf/brasatech-server.p12
COPY ./certs/truststore.p12 conf/truststore.p12
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]