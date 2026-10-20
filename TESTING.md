# Testing guide for Cruise Control Helm Chart

Commands below assume the chart is checked out locally and run from the repository root.
Use throwaway namespaces named `cc3-test-*` and delete them when you finish.

## Configuration testing

### 1. Service account

```bash
helm install cc charts/cruise-control -n cc3-test-sa --create-namespace \
  --set serviceAccount.create=true \
  --set serviceAccount.name=cc-test-sa
kubectl get serviceaccount -n cc3-test-sa
```

### 2. Kafka connection

Clusters are defined under `clusters.<name>`, and the Kafka address goes in `config.bootstrap.servers`:

```bash
helm install cc charts/cruise-control -n cc3-test-conf --create-namespace \
  --set 'clusters.my-cluster.config.bootstrap\.servers=kafka:9092'
```

Kafka in KRaft mode needs no ZooKeeper settings.

### 3. Resources

```bash
helm install cc charts/cruise-control -n cc3-test-res --create-namespace \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi
```

## Validation tests

Replace `cc3-test-conf` with the namespace you used.

### 1. Pod health

```bash
kubectl describe pod -l app.kubernetes.io/name=cruise-control -n cc3-test-conf
```

### 2. Service connectivity

The Service listens on port 80 and forwards to the pod port 9090. There is one Service per cluster:

```bash
kubectl get svc -n cc3-test-conf
kubectl port-forward svc/<cluster-service> 9090:80 -n cc3-test-conf
curl http://localhost:9090/kafkacruisecontrol/state
```

### 3. Logs

```bash
kubectl logs -l app.kubernetes.io/name=cruise-control -n cc3-test-conf
```

To check the log4j2 configuration is effective, list `/cruise-control/config` in the pod and look for `log4j2.properties`.

## UI flavors

`ui.flavor` is `new` (default, the Go UI configured with `CCUI_*` variables) or `legacy` (the frozen LinkedIn UI behind nginx). There is no `helm unittest` in this repo, so these checks are `helm template` renders with the release name `t`; run them from the repository root.

Default flavor: the new image, no nginx ConfigMap, no `volumes:`, `enableServiceLinks: false`.

```bash
helm template t charts/cruise-control --show-only templates/ui/deployment.yaml | grep -E 'image:|enableServiceLinks|CCUI_AUTH_MODE'
helm template t charts/cruise-control | grep -c ui-config                                  # 0
helm template t charts/cruise-control --show-only templates/ui/deployment.yaml | grep -cE 'nginx|config.csv|volumes:|volumeMounts:'   # 0
```

Legacy flavor: the 0.4.0 image, the nginx ConfigMap and its mounts, no `CCUI_*` variables.

```bash
helm template t charts/cruise-control --set ui.flavor=legacy --show-only templates/ui/deployment.yaml | grep -E 'image:|nginx|config.csv'
helm template t charts/cruise-control --set ui.flavor=legacy --show-only templates/ui/configmap.yaml | grep -E 'nginx.conf|config.csv'
helm template t charts/cruise-control --set ui.flavor=legacy --set ui.auth.mode=local --show-only templates/ui/deployment.yaml | grep -c CCUI_   # 0
```

Invalid values fail with a message that names the key:

```bash
helm template t charts/cruise-control --set ui.flavor=foo
helm template t charts/cruise-control --set ui.auth.mode=ldap
```

Clusters are numbered in alphabetical order, whatever the order in the values:

```bash
helm template t charts/cruise-control --set clusters.cluster-prod.group=production --set clusters.cluster-dev.group=develop \
  --show-only templates/ui/deployment.yaml | grep -E 'CLUSTERS__[01]__(NAME|URL)' -A1
```

A variable in `ui.env`, `ui.envFromConfigMap` or `ui.envFromSecrets` replaces the generated one, and there is one `env:` key whatever sources you combine:

```bash
helm template t charts/cruise-control --set ui.env.CCUI_CLUSTERS__0__URL=http://other:9090/kafkacruisecontrol \
  --show-only templates/ui/deployment.yaml | grep -c CCUI_CLUSTERS__0__URL                 # 1
for flavor in new legacy; do
  helm template t charts/cruise-control --set ui.flavor=$flavor --set ui.env.A=b \
    --set ui.envFromSecrets.X.name=s --set ui.envFromSecrets.X.key=k \
    --set ui.envFromConfigMap.Y.name=c --set ui.envFromConfigMap.Y.key=k \
    --show-only templates/ui/deployment.yaml | grep -c 'env:$'                               # 1
done
```

Probes use `/healthz` in `new` and `/health` in `legacy`:

```bash
helm template t charts/cruise-control --set ui.readinessProbe.enabled=true --show-only templates/ui/deployment.yaml | grep 'path: /healthz'
helm template t charts/cruise-control --set ui.flavor=legacy --set ui.readinessProbe.enabled=true --show-only templates/ui/deployment.yaml | grep 'path: /health'
```

Pods restart on a change: the legacy `checksum/config` annotation changes when you add a cluster, and in `new` the pod template itself changes.

```bash
helm template t charts/cruise-control --set ui.flavor=legacy --show-only templates/ui/deployment.yaml | grep checksum
helm template t charts/cruise-control --set ui.flavor=legacy --set clusters.extra.group=x --show-only templates/ui/deployment.yaml | grep checksum
```

On OrbStack, install with the default flavor and no login, open the UI with a port-forward and visit every page. Then repeat with `--set ui.flavor=legacy`, and with `-f tests/ci-values-local.yaml` to try the `local` login (the users and the session secret in that file are throwaway test values):

```bash
helm install cc charts/cruise-control -n cc3-test-ui --create-namespace -f tests/ci-values.yaml
kubectl --context orbstack -n cc3-test-ui port-forward svc/cc-cruise-control-ui 8080:80
```

`ct install` (CI) only covers the default flavor, with `ci/ci-common-values.yaml`. The legacy flavor is covered by the renders above.

## Local tests with chart-testing (ct)

These tests use the `orbstack` kubectl context. OrbStack shares the Docker image store with the local Docker engine, so an image built locally can be used with `image.pullPolicy=IfNotPresent` or `Never`.

1. Deploy a single-node KRaft Kafka. [.github/kafka-kraft.yaml](.github/kafka-kraft.yaml) creates it in the `kafka` namespace, which is what `ci/ci-common-values.yaml` expects. To keep it in a `cc3-test-*` namespace, copy the file, rename the namespace and the advertised address, and pass the new bootstrap address with `--helm-extra-set-args` below:

   ```bash
   kubectl --context orbstack apply -f .github/kafka-kraft.yaml
   kubectl --context orbstack -n kafka rollout status sts/my-cluster-kafka
   ```

2. Lint and install:

   ```bash
   ct lint --config .github/ct.yaml
   ct install --config .github/ct.yaml
   ```

   For a locally built image, add for example
   `--helm-extra-set-args "--set=image.repository=local/kcc --set=image.pullPolicy=Never"`.

3. Run the chart tests against a release. The test pod is off by default, so install
   the release with `--set testConnection.enabled=true` first:

   ```bash
   helm test cc -n cc3-test-conf
   ```

## Clean-up

```bash
helm uninstall cc -n cc3-test-conf
kubectl delete namespace cc3-test-conf cc3-test-sa cc3-test-res
kubectl --context orbstack get ns | grep cc3-test   # must be empty
```

If you deployed Kafka for the `ct` tests, remove it too (`kubectl --context orbstack delete -f .github/kafka-kraft.yaml`).
