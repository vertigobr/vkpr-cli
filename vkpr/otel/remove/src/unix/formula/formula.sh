#!/usr/bin/env bash

runFormula() {
  info "Removing OTEL..."
  $VKPR_KUBECTL delete instrumentations.opentelemetry.io/instrumentation -n "$VKPR_ENV_GLOBAL_NAMESPACE" 2> /dev/null || error "VKPR OTEL-INSTRUMENTATION not found"

  $VKPR_HELM uninstall -n "$VKPR_ENV_GLOBAL_NAMESPACE" opentelemetry-operator 2> /dev/null || error "VKPR OTEL_OPERATOR not found"

  $VKPR_KUBECTL delete -n "$VKPR_ENV_GLOBAL_NAMESPACE" -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel
spec:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:

    exporters:
      logging: 
        loglevel: debug
      jaeger:
        endpoint: jaeger-collector.vkpr:14250
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: []
          exporters: [logging ,jaeger]
EOF
}