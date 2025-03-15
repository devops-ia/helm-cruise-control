# Testing guide for Cruise Control Helm Chart

## Configuration testing

### 1. Service Account testing

Test the service account creation:

```bash
helm install cruise-control devops-ia/cruise-control \
  --namespace cruise-control-test \
  --set serviceAccount.create=true \
  --set serviceAccount.name=cc-test-sa
```

Verify:

```bash
kubectl get serviceaccount -n cruise-control-test
```

### 2. Custom configuration testing

Test with custom environment variables:

```bash
helm install cruise-control devops-ia/cruise-control \
  --namespace cruise-control-test \
  --set env.KAFKA_BOOTSTRAP_SERVERS=kafka:9092
```

### 3. Resource configuration testing

Test with custom resource limits:

```bash
helm install cruise-control devops-ia/cruise-control \
  --namespace cruise-control-test \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi
```

## Validation tests

### 1. Pod health check

```bash
kubectl describe pod -l app.kubernetes.io/name=cruise-control -n cruise-control-test
```

### 2. Service connectivity test

```bash
kubectl port-forward svc/cruise-control 8090:8090 -n cruise-control-test
curl http://localhost:8090/kafkacruisecontrol/state
```

### 3. Log verification

```bash
kubectl logs -l app.kubernetes.io/name=cruise-control -n cruise-control-test
```

## Clean-up

Remove test deployment:

```bash
helm uninstall cruise-control -n cruise-control-test
kubectl delete namespace cruise-control-test
```

## Automated testing

The chart includes CI tests in the `ci/` directory. These tests can be run using:

```bash
helm test cruise-control -n cruise-control-test
```
