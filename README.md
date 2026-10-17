# Cruise Control Helm Chart

[Cruise Control](https://github.com/cruise-control-for-kafka/cruise-control) is a product that helps run Apache Kafka clusters at large scale. Due to the popularity of Apache Kafka, many companies have bigger and bigger Kafka clusters.

> [!WARNING]
> Chart 3.0.0 (expected) deploys Cruise Control 3.x only. See the [migration notes](charts/cruise-control/README.md#migrating-from-chart-2x).

The default images come from [devops-ia/kafka-cruise-control](https://github.com/devops-ia/kafka-cruise-control) (`ghcr.io/devops-ia/kafka-cruise-control`, `devopsiaci/cruise-control` and the matching `-ui` images). The reasons, how to use another image and the version matrix are in the [chart README](charts/cruise-control/README.md#container-images).

## Usage

Charts are available in:

* [Chart Repository](https://helm.sh/docs/topics/chart_repository/)
* [OCI Artifacts](https://helm.sh/docs/topics/registries/)

### Chart Repository

#### Add repository

```console
helm repo add cruise-control https://devops-ia.github.io/helm-cruise-control
helm repo update
```

#### Install Helm chart

```console
helm install [RELEASE_NAME] cruise-control/cruise-control
```

This install all the Kubernetes components associated with the chart and creates the release.

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

### OCI Registry

Charts are also available in OCI format. The list of available charts can be found [here](https://github.com/devops-ia/helm-cruise-control/pkgs/container/helm-cruise-control%2Fcruise-control).

#### Install Helm chart

```console
helm install [RELEASE_NAME] oci://ghcr.io/devops-ia/helm-cruise-control/cruise-control --version=[version]
```

## Cruise Control chart

Can be found in [cruise-control chart](charts/cruise-control).
