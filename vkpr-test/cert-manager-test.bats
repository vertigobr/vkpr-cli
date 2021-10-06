VKPR_HOME=~/.vkpr

setup_file() {
    #load 'common-setup'
    #_common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: starting private ACME server..." >&3
        DOCKER0_IP=$(ifconfig docker0 | grep "inet " | awk '{printf $2}'0)
        docker run --rm -d --name step \
        -p 9000:9000 \
        --add-host "host.k3d.internal:$DOCKER0_IP" \
        -e "DOCKER_STEPCA_INIT_NAME=Smallstep" \
        -e "DOCKER_STEPCA_INIT_DNS_NAMES=host.k3d.internal,localhost,step,$(hostname -f)" \
        smallstep/step-ca
        sleep 20
        docker exec step step ca provisioner add acme --type ACME
        docker kill -s 1 step

        #docker logs -f step

        echo "setup: copying root_ca.crt from ACME server..." >&3
        docker cp step:/home/step/certs/root_ca.crt /tmp/
        chmod +r /tmp/root_ca.crt

        echo "setup: initialising infra. Cluster running on port 80 , 443 is manadatory for this test." >&3
        rit vkpr infra start --http_port 80 --https_port 443 --default
        $VKPR_KUBECTL wait --all-namespaces --for=condition=ready --timeout=20m pod --all
        sleep 2

        echo "setup: Copying root_ca.crt to cert-manager namespace.." >&3
        $VKPR_HOME/bin/kubectl create namespace cert-manager
        $VKPR_HOME/bin/kubectl create secret generic custom-ca-secret --namespace cert-manager \
        --from-file=ca-certificates.crt=/tmp/root_ca.crt

        echo "setup: installing cert-manager...." >&3
        rit vkpr cert-manager install custom-acme --email eu@aqui.com
        $VKPR_HOME/bin/kubectl wait --all-namespaces --for=condition=ready --timeout=5m pod --all
        sleep 2

        echo "setup: instaling ingress..." >&3
        rit vkpr ingress install
        $VKPR_HOME/bin/kubectl wait --all-namespaces --for=condition=ready --timeout=5m pod --all
        sleep 2

        echo "setup: installing whoami to create a certificate...." >&3
        rit vkpr whoami install --domain "host.k3d.internal"
        $VKPR_HOME/bin/kubectl wait --all-namespaces --for=condition=ready --timeout=5m pod --all
        sleep 1m
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "curl to https://host.k3d.internal must return a Smallstep certificate" {
   run "$(curl -vvv -k --resolve host.k3d.internal:443:127.0.0.1 https://host.k3d.internal 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }')"
    actual="${lines[4]}"
    trim "$actual"
    actual="$TRIMMED"
    expected="*  issuer: O=Smallstep; CN=Smallstep Intermediate CA"
    assert_equal "$actual" "$expected"
    
}


trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    TRIMMED="$var"
}
