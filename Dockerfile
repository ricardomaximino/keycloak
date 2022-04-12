FROM quay.io/keycloak/keycloak:17.0.1
# FROM jboss/keycloak

COPY ./themes/ /opt/keycloak/themes
# COPY ./themes/ /opt/jboss/keycloak/themes