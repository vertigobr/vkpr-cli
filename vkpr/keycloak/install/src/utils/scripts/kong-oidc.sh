#!/bin/sh

kcadm.sh config credentials --server http://localhost:8080 \
  --realm master --user LOGIN_USERNAME --password LOGIN_PASSWORD \
  --config /tmp/kcadm.config

# realm
kcadm.sh create realms \
  -s realm=kong -s enabled=true \
  -s editUsernameAllowed=true -s resetPasswordAllowed=true \
  -s rememberMe=true -s registrationEmailAsUsername=true \
  --config /tmp/kcadm.config

# clientid
kcadm.sh create clients -r kong \
  -s clientId=kong-manager -s enabled=true \
  -s clientAuthenticatorType=client-secret -s secret="CLIENT_SECRET" \
  -s 'redirectUris=["KONG_DOMAIN/*"]' -s directAccessGrantsEnabled=true \
  -s rootUrl="KONG_DOMAIN/" -s adminUrl=KONG_DOMAIN \
  -s 'webOrigins=["KONG_DOMAIN"]' \
  --config /tmp/kcadm.config

ID_CLIENTID=$(kcadm.sh get clients -r kong --format csv --fields id,clientId --config /tmp/kcadm.config | grep kong-manager | cut -d "," -f1 | sed s/\"//g)

##### ID do clients
kcadm.sh create clients/$ID_CLIENTID/roles -r kong \
  -s name=default:super-admin -s 'description=admin' \
  --config /tmp/kcadm.config
##### ID do clients
kcadm.sh create clients/$ID_CLIENTID/roles -r kong \
  -s name=default:admin -s 'description=editor' \
  --config /tmp/kcadm.config
##### ID do clients
kcadm.sh create clients/$ID_CLIENTID/roles -r kong \
  -s name=default:read-only -s 'description=viewer' \
  --config /tmp/kcadm.config
##### Protocol Mapper
kcadm.sh create clients/$ID_CLIENTID/protocol-mappers/models -r kong \
  -s name="client roles" -s consentRequired=false \
  -s protocol="openid-connect" -s protocolMapper="oidc-usermodel-client-role-mapper" \
  -s 'config."multivalued"=true' -s 'config."userinfo.token.claim"=true' \
  -s 'config."id.token.claim"=true' -s 'config."access.token.claim"=true' \
  -s 'config."claim.name"=roles' -s 'config."jsonType.label"=String' \
  -s 'config."usermodel.clientRoleMapping.clientId"=kong-manager' \
  --config /tmp/kcadm.config

# usuário admin
kcadm.sh create users -r kong \
  -s enabled=true -s email=sample-admin@example.com \
  -s firstName=Sample -s lastName=Admin \
  --config /tmp/kcadm.config

kcadm.sh set-password -r kong \
  --username=sample-admin@example.com --new-password="TEMPORARY_PASSWORD" \
  --temporary \
  --config /tmp/kcadm.config

kcadm.sh add-roles -r kong \
  --uusername=sample-admin@example.com \
  --cclientid=kong-manager --rolename default:super-admin \
  --config /tmp/kcadm.config


# usuário editor
kcadm.sh create users -r kong \
  -s enabled=true -s email=sample-editor@example.com \
  -s firstName=Sample -s lastName=editor \
  --config /tmp/kcadm.config

kcadm.sh set-password -r kong \
  --username=sample-editor@example.com --new-password="TEMPORARY_PASSWORD" \
  --temporary \
  --config /tmp/kcadm.config

kcadm.sh add-roles -r kong \
  --uusername=sample-editor@example.com \
  --cclientid=kong-manager --rolename default:admin \
  --config /tmp/kcadm.config


# usuário viewer
kcadm.sh create users -r kong \
  -s enabled=true -s email=sample-viewer@example.com \
  -s firstName=Sample -s lastName=viewer \
  --config /tmp/kcadm.config

kcadm.sh set-password -r kong \
  --username=sample-viewer@example.com --new-password="TEMPORARY_PASSWORD" \
  --temporary \
  --config /tmp/kcadm.config

kcadm.sh add-roles -r kong \
  --uusername=sample-viewer@example.com \
  --cclientid=kong-manager --rolename default:read-only \
  --config /tmp/kcadm.config

rm /tmp/kcadm.config
