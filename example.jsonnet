local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring',
      versions+:: {
              alertmanager: "v0.19.0",
              nodeExporter: "v0.18.1",
              kubeStateMetrics: "v1.8.0",
              kubeRbacProxy: "v0.4.1",
              prometheusOperator: "v0.33.0",
              prometheus: "v2.13.1",
          },

          imageRepos+:: {
              prometheus: "quay.io/prometheus/prometheus",
              alertmanager: "quay.io/prometheus/alertmanager",
              kubeStateMetrics: "quay.io/coreos/kube-state-metrics",
              kubeRbacProxy: "quay.io/coreos/kube-rbac-proxy",
              nodeExporter: "quay.io/prometheus/node-exporter",
              prometheusOperator: "quay.io/coreos/prometheus-operator",
          },

          prometheus+:: {
              names: 'k8s',
              replicas: 2,
              rules: {},
          },

          alertmanager+:: {
            name: 'main',
            config: |||
              global:
                resolve_timeout: 5m
              route:
                group_by: ['job']
                group_wait: 30s
                group_interval: 5m
                repeat_interval: 12h
                receiver: 'null'
                routes:
                - match:
                    alertname: Watchdog
                  receiver: 'null'
              receivers:
              - name: 'null'
            |||,
            replicas: 3,
          },

          kubeStateMetrics+:: {
            collectors: '',  // empty string gets a default set
            scrapeInterval: '30s',
            scrapeTimeout: '30s',

            baseCPU: '100m',
            baseMemory: '150Mi',
          },

          nodeExporter+:: {
            port: 9100,
          },
    },
  };

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
