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
