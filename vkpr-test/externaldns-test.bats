#
# External-DNS Tests
#
# We are starting a local PowerDNS authoritative server and creating a new "example.com" domain during setup.
# Mora bout this in https://doc.powerdns.com/authoritative/PowerDNS-Authoritative.pdf.
#
VKPR_HOME=~/.vkpr

setup_file() {
    load 'common-setup'
    _common_setup
    if [ "$VKPR_TEST_SKIP_SETUP" == "true" ]; then
        echo "setup: skipping setup due to VKPR_TEST_SKIP_SETUP=true" >&3
    else
        echo "setup: starting powerdns..." >&3
        startPowerDNS
        echo "setup: installing externaldns...." >&3
        rit vkpr external-dns install --provider="powerDNS" --pdns_apiurl="http://host.k3d.internal"
        echo "setup: creating and exposing annotated service...." >&3
        $VKPR_HOME/bin/kubectl apply -f $BATS_TEST_DIRNAME/exposed-service.yml
        # wait to exposed service assign the external ip
        local WAIT_IP=""
        while [[ -z $WAIT_IP ]]; do
            WAIT_IP=$($VKPR_HOME/bin/kubectl get svc nginx --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
            if [[ -z $WAIT_IP ]]; then
                sleep 10
            fi
        done
    fi
}

setup() {
    load $VKPR_HOME/bats/bats-support/load.bash
    load $VKPR_HOME/bats/bats-assert/load.bash
}

@test "tests name resolution of k3d host internal alias (host.k3d.internal)" {
    run getHostIP
}

@test "dig test of powerdns container 'local.example.com'" {
    # ensures powerdns has been initialized correctly
    run digLocal
    assert_output "127.0.0.1"
}

@test "testing if external-dns dealt with exposed annotated service" {
    external_ip="$($VKPR_HOME/bin/kubectl get svc nginx -o jsonpath="{.status.loadBalancer.ingress[1].ip}")
$($VKPR_HOME/bin/kubectl get svc nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}")"
    refute [ -z "$external_ip" ]
    run digExposedService
    assert_output "$external_ip"
}

getHostIP() {
    $VKPR_HOME/bin/kubectl run --rm=true -i busybox --image=busybox --restart=Never \
        --command -- ping -c1 -n host.k3d.internal | head -n1 | sed 's/.*(\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)).*/\1/g'
}

digLocal(){
    dig @localhost -4 -p 8553 local.example.com +short
}

digExposedService(){
    dig @localhost -4 -p 8553 nginx.example.com +short
}

startPowerDNS() {
    # creates rit powerdns credential
    rit set credential --provider='powerdns' --fields="apikey" --values="mykey"
    # define log/cache cfg (IMPORTANTE zerar os tempos de cache)
    cp $BATS_TEST_DIRNAME/dnslog.j2 /tmp/dnslog.j2
    # start powerdns
    docker run -d --name pdns \
        -p 8553:53/tcp -p 8553:53/udp -p 8081:8081 \
        -e PDNS_AUTH_API_KEY=mykey \
        -e TEMPLATE_FILES="dnslog" \
        -v /tmp/dnslog.j2:/etc/powerdns/templates.d/dnslog.j2:ro \
        powerdns/pdns-auth-45
    # creates dns zone
    docker exec pdns pdnsutil create-zone example.com
    docker exec pdns pdnsutil set-kind example.com native
    docker exec pdns pdnsutil set-meta example.com SOA-EDIT INCEPTION-INCREMENT
    docker exec pdns pdnsutil increase-serial example.com
    docker exec pdns pdnsutil add-record example.com local A 60 "127.0.0.1"
}

teardown_file() {
    if [ "$VKPR_TEST_SKIP_TEARDOWN" == "true" ]; then
        echo "teardown: skipping teardown due to VKPR_TEST_SKIP_TEARDOWN=true" >&3
    else
        echo "teardown: removing annotated service...." >&3
        $VKPR_HOME/bin/kubectl delete --ignore-not-found=true -f $BATS_TEST_DIRNAME/exposed-service.yml
        echo "teardown: stopping power-dns...." >&3
        docker rm -f pdns
        echo "teardown: uninstalling external-dns...." >&3
        rit vkpr external-dns remove
    fi
    _common_teardown
}