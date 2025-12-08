## Examples

This directory contains various example configurations for deploying Kafka Cruise Control using the Helm chart. Each example demonstrates different use cases and configurations.

### `clustersDefaults`

This section defines the default configuration that will be shared across **all clusters**. It includes:

* `jaas`: JAAS authentication configuration
* `cluster`: cluster-level settings (min.insync.replicas, etc.)
* `capacity`: broker capacity configuration
* `config`: cruise Control properties
* `log4j`: logging configuration

### `clusters`

This section defines individual Kafka clusters. Each cluster inherits from `clustersDefaults` and can override any setting. You can define:

* **Single**: define one cluster with minimal overrides
* **Multiple**: define multiple clusters with cluster-specific settings

### Configuration inheritance

The configuration follows this inheritance pattern:

1. Base configuration comes from `clustersDefaults`
2. Cluster-specific values in `clusters.<cluster-name>` override the defaults
3. Only specify what differs per cluster * everything else is inherited

## Quick start examples

### Minimal setup (single cluster)

Use [09-minimal.yaml](09-minimal.yaml) for the simplest possible configuration.

```bash
helm install cruise-control ./cruise-control -f examples/09-minimal.yaml
```

### Basic configuration (single cluster)

Use [01-basic-configuration.yaml](01-basic-configuration.yaml) for a standard setup.

```bash
helm install cruise-control ./cruise-control -f examples/01-basic-configuration.yaml
```

### Multi-cluster simple

Use [10-multi-cluster-simple.yaml](10-multi-cluster-simple.yaml) for managing multiple Kafka clusters.

```bash
helm install cruise-control ./cruise-control -f examples/10-multi-cluster-simple.yaml
```

## Samples

### Single cluster samples

| Example | Description | Use Case |
|---------|-------------|----------|
| [09-minimal.yaml](09-minimal.yaml) | Absolute minimum configuration | Quick testing, POC |
| [01-basic-configuration.yaml](01-basic-configuration.yaml) | Basic production-ready setup | Standard deployments |
| [02-high-availability.yaml](02-high-availability.yaml) | HA setup with multiple replicas | High availability requirements |
| [03-secure-tls.yaml](03-secure-tls.yaml) | TLS and security features | Secure environments |
| [04-custom-advanced.yaml](04-custom-advanced.yaml) | Advanced customization with JBOD | Complex storage configurations |
| [05-development.yaml](05-development.yaml) | Development environment | Local/dev testing |
| [08-performance-tuned.yaml](08-performance-tuned.yaml) | Performance optimizations | High-throughput scenarios |

### Multi-cluster examples

| Example | Description | Use Case |
|---------|-------------|----------|
| [10-multi-cluster-simple.yaml](10-multi-cluster-simple.yaml) | Simple multi-cluster setup | Managing 2-3 clusters |
| [06-production.yaml](06-production.yaml) | Production multi-env (dev/staging/prod) | Complete environment setup |
| [07-multi-region.yaml](07-multi-region.yaml) | Multi-region deployment | Global deployments |

## Samples

### Sample 1: single cluster with defaults

```yaml
clustersDefaults:
  config:
    bootstrap.servers: "kafka-broker:9092"
    prometheus.server.endpoint: "thanos-query:9090"

clusters:
  production: {}  # Inherits all defaults
```

### Sample 2: multiple clusters with overrides

```yaml
clustersDefaults:
  config:
    client.id: "cruise-control"
    sample.store.topic.replication.factor: 2
  log4j:
    rootLogger.level: INFO

clusters:
  dev:
    config:
      bootstrap.servers: "kafka-dev:9092"
    log4j:
      rootLogger.level: DEBUG  # Override for dev

  prod:
    config:
      bootstrap.servers: "kafka-prod:9092"
      sample.store.topic.replication.factor: 3  # Override for prod
```

### Sample 3: different capacity per cluster

```yaml
clustersDefaults:
  capacity:
    type: capacity
    config: |
      {
        "brokerCapacities":[{
          "brokerId": "-1",
          "capacity": {
            "DISK": "100000",
            "CPU": "100"
          }
        }]
      }

clusters:
  small-cluster: {}  # Uses default capacity

  large-cluster:
    capacity:
      config: |
        {
          "brokerCapacities":[{
            "brokerId": "-1",
            "capacity": {
              "DISK": "500000",
              "CPU": "200"
            }
          }]
        }
```

## Multi-cluster UI access

When deploying multiple clusters, the chart automatically deploys a UI with nginx reverse proxy:

```yaml
ui:
  enabled: true
  ingress:
    enabled: true
    hosts:
      - host: cruise-control.example.com
```

Access clusters via:

* `https://cruise-control.example.com/cluster-a/`
* `https://cruise-control.example.com/cluster-b/`

## Configuration

### 1: shared security settings

```yaml
clustersDefaults:
  jaas:
    enabled: true
    config: |
      KafkaClient {
        org.apache.kafka.common.security.plain.PlainLoginModule required
        username="cruise-control"
        password="changeme";
      };

clusters:
  cluster-a:
    config:
      bootstrap.servers: "kafka-a:9092"
  cluster-b:
    config:
      bootstrap.servers: "kafka-b:9092"
```

### 2: environment-specific settings

```yaml
clustersDefaults:
  config:
    self.healing.enabled: false
    anomaly.detection.interval.ms: "10000"

clusters:
  dev:
    group: "development"
    log4j:
      rootLogger.level: DEBUG

  prod:
    group: "production"
    config:
      self.healing.enabled: true
    log4j:
      rootLogger.level: WARN
```

### 3: different capacity types

```yaml
clustersDefaults:
  capacity:
    type: capacity

clusters:
  standard-cluster:
    capacity:
      config: |
        {"brokerCapacities": [...]}

  jbod-cluster:
    capacity:
      type: capacityJBOD
      config: |
        {"brokerCapacities": [{
          "capacity": {
            "DISK": {
              "/mnt/data1": "1000000",
              "/mnt/data2": "1000000"
            }
          }
        }]}
```

## Samples

To test an example configuration without deploying:

```bash
# Render templates
helm template cruise-control ./cruise-control -f examples/01-basic-configuration.yaml

# Validate
helm install cruise-control ./cruise-control -f examples/01-basic-configuration.yaml --dry-run --debug

# Check generated ConfigMaps
helm template cruise-control ./cruise-control -f examples/06-production.yaml | grep -A 50 "kind: ConfigMap"
```

## Migration from Old Configuration

If you're migrating from the old configuration structure (using `env` variables), convert your settings to the new structure:

```yaml
clustersDefaults:
  cluster:
    min.insync.replicas: 2
  config:
    bootstrap.servers: "kafka:9092"

clusters:
  my-cluster: {}
```

## Getting help

* Review the [values.yaml](../values.yaml) for all available configuration options
* Check the [README.md](../README.md) for detailed chart documentation
* Examine template files in [templates/](../templates/) to understand how values are used
