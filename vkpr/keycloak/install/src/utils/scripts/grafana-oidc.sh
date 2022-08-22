#!/bin/sh

kcadm.sh config credentials --server http://localhost:8080 \
  --realm master --user LOGIN_USERNAME --password LOGIN_PASSWORD \
  --config /tmp/kcadm.config

# realm
kcadm.sh create realms \
  -s realm=grafana -s enabled=true \
  -s editUsernameAllowed=true -s resetPasswordAllowed=true \
  -s rememberMe=true -s registrationEmailAsUsername=true \
  --config /tmp/kcadm.config

# clientid
kcadm.sh create clients -r grafana \
  -s clientId=grafana -s enabled=true \
  -s clientAuthenticatorType=client-secret -s secret="CLIENT_SECRET" \
  -s 'redirectUris=["GRAFANA_DOMAIN/*"]' -s directAccessGrantsEnabled=true \
  -s rootUrl="GRAFANA_DOMAIN/" -s adminUrl=GRAFANA_ADDRESS_BASE \
  -s 'webOrigins=["GRAFANA_ADDRESS_BASE"]' \
  --config /tmp/kcadm.config

ID_CLIENTID=$(kcadm.sh get clients -r grafana --format csv --fields id,clientId --config /tmp/kcadm.config | grep grafana | cut -d "," -f1 | sed s/\"//g)

##### ID do clients
kcadm.sh create clients/$ID_CLIENTID/roles -r grafana \
  -s name=admin -s 'description=admin' \
  --config /tmp/kcadm.config
##### ID do clients
kcadm.sh create clients/$ID_CLIENTID/roles -r grafana \
  -s name=editor -s 'description=editor' \
  --config /tmp/kcadm.config
##### ID do clients
kcadm.sh create clients/$ID_CLIENTID/roles -r grafana \
  -s name=viewer -s 'description=viewer' \
  --config /tmp/kcadm.config
##### Protocol Mapper
kcadm.sh create clients/$ID_CLIENTID/protocol-mappers/models -r grafana \
  -s name="client roles" -s consentRequired=false \
  -s protocol="openid-connect" -s protocolMapper="oidc-usermodel-client-role-mapper" \
  -s 'config."multivalued"=true' -s 'config."userinfo.token.claim"=true' \
  -s 'config."id.token.claim"=true' -s 'config."access.token.claim"=true' \
  -s 'config."claim.name"=roles' -s 'config."jsonType.label"=String' \
  -s 'config."usermodel.clientRoleMapping.clientId"=grafana' \
  --config /tmp/kcadm.config

# usuário admin
kcadm.sh create users -r grafana \
  -s enabled=true -s email=sample-admin@example.com \
  -s firstName=Sample -s lastName=Admin \
  --config /tmp/kcadm.config

kcadm.sh set-password -r grafana \
  --username=sample-admin@example.com --new-password="TEMPORARY_PASSWORD" \
  --temporary \
  --config /tmp/kcadm.config

kcadm.sh add-roles -r grafana \
  --uusername=sample-admin@example.com \
  --cclientid=grafana --rolename admin \
  --config /tmp/kcadm.config


# usuário editor
kcadm.sh create users -r grafana \
  -s enabled=true -s email=sample-editor@example.com \
  -s firstName=Sample -s lastName=editor \
  --config /tmp/kcadm.config

kcadm.sh set-password -r grafana \
  --username=sample-editor@example.com --new-password="TEMPORARY_PASSWORD" \
  --temporary \
  --config /tmp/kcadm.config

kcadm.sh add-roles -r grafana \
  --uusername=sample-editor@example.com \
  --cclientid=grafana --rolename editor \
  --config /tmp/kcadm.config


# usuário viewer
kcadm.sh create users -r grafana \
  -s enabled=true -s email=sample-viewer@example.com \
  -s firstName=Sample -s lastName=viewer \
  --config /tmp/kcadm.config

kcadm.sh set-password -r grafana \
  --username=sample-viewer@example.com --new-password="TEMPORARY_PASSWORD" \
  --temporary \
  --config /tmp/kcadm.config

kcadm.sh add-roles -r grafana \
  --uusername=sample-viewer@example.com \
  --cclientid=grafana --rolename viewer \
  --config /tmp/kcadm.config

rm /tmp/kcadm.config
