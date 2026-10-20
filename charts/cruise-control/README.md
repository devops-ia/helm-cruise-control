# cruise-control

A Helm chart to deploy Cruise Control for Apache Kafka

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| ialejandro | <hello@ialejandro.rocks> | <https://ialejandro.rocks> |

> [!WARNING]
> **BREAKING: this chart deploys Cruise Control 3.x only.** Chart 3.0.0 dropped 2.x, and chart 4.0.0 makes the new UI the default. See [Migrating from chart 2.x](#migrating-from-chart-2x).

## Container images

The server image is built from [devops-ia/kafka-cruise-control](https://github.com/devops-ia/kafka-cruise-control) and the UI image from [devops-ia/kafka-cruise-control-ui](https://github.com/devops-ia/kafka-cruise-control-ui):

| Component | GHCR | Docker Hub |
|-----------|------|------------|
| Server | [ghcr.io/devops-ia/kafka-cruise-control](https://github.com/devops-ia/kafka-cruise-control/pkgs/container/kafka-cruise-control) | [devopsiaci/cruise-control](https://hub.docker.com/r/devopsiaci/cruise-control) |
| UI (new, default) | [ghcr.io/devops-ia/kafka-cruise-control-ui](https://github.com/devops-ia/kafka-cruise-control-ui/pkgs/container/kafka-cruise-control-ui) | [devopsiaci/kafka-cruise-control-ui](https://hub.docker.com/r/devopsiaci/kafka-cruise-control-ui) |
| UI (legacy, frozen at `0.4.0`) | `ghcr.io/devops-ia/kafka-cruise-control-ui:0.4.0` | `devopsiaci/cruise-control-ui:0.4.0` |

Why this chart uses them:

* [Upstream](https://github.com/cruise-control-for-kafka/cruise-control) attaches no jar or tgz assets to its releases, so the image is built from the git tag.
* The server image bundles what the chart expects: the server, the AWS MSK IAM auth jar and the metrics reporter jar (`/cruise-control/cruise-control/build/dependant-libs/cruise-control-metrics-reporter.jar`). The UI is a separate image.
* Both run as non-root (server uid 65534; the new UI is distroless and non-root; the legacy UI runs as uid 101).
* Images are multi-arch (`linux/amd64`, `linux/arm64`) and published with an SBOM. The GHCR images also carry a build provenance attestation.
* Server tags look like `jdk<N>-cc<version>-iam<version>`. updatecli bumps them, so the chart `appVersion` follows.
* Only Cruise Control 3.x is built. JDK 17 (default) and 21 are published. JDK 25 is not: the 3.1.0 build uses Gradle 8.5, which cannot run on it.

To use another image, set `image.repository` / `image.tag` (server), `ui.image.repository` / `ui.image.tag` (new UI) and `ui.legacy.image.repository` / `ui.legacy.image.tag` (legacy UI). A custom server image must provide:

* the Cruise Control start script at `/cruise-control/kafka-cruise-control-start.sh` and its config under `/cruise-control/config/` (the chart mounts `cruisecontrol.properties`, `capacity.json`, `clusterConfigs.json` and `log4j2.properties` there),
* `log4j2.properties` as the logging file (`log4j.properties` is not read by 3.x),
* the web server on port 9090.

## Compatibility

"Tested" means checked for this change on a local cluster. "Docs" means taken from the upstream or image documentation, not tested here.

| Chart | Cruise Control | Default image tag | JDK | Kafka | UI | Log file | Notes |
|-------|----------------|-------------------|-----|-------|----|----------|-------|
| 2.x | 2.5.146 (docs) | `jdk17-cc2.5.146-iam2.3.9` (docs) | 17 (docs) | 2.5 to 4.3 (docs) | 0.4.0 (docs) | `log4j.properties` (docs) | ZooKeeper settings were accepted. No longer maintained here. |
| 3.0.0 (expected) | 3.1.0 (tested) | `jdk17-cc3.1.0-iam2.3.9` (tested) | 17 (tested), 21 (tested), 25 not published | 2.5 to 4.3 (docs); 3.9.1 KRaft (tested) | 1.0.0 new (docs), 0.4.0 legacy (tested) | `log4j2.properties` (tested) | ZooKeeper optional (tested without). Metrics reporter on the brokers must match the server version (docs). |

## Migrating from chart 2.x

* Only Cruise Control 3.x is supported. To stay on 2.x, pin `image.tag` to `jdk17-cc2.5.146-iam2.3.9` and keep using chart 2.x; this is unsupported.
* `clustersDefaults.log4j` (and `clusters.<name>.log4j`) is now mounted as `config/log4j2.properties`, which is the file 3.x loads. The values keep the same log4j2 syntax. Your own mounts onto `config/log4j.properties` (for example through `volumeMounts`) are no longer read.
* Update the metrics reporter on every Kafka broker to 3.1.0, together with the server.
* `metric.sampling.interval.ms` must be at least 60000. With 30000 or 45000 the server exits at startup with `ConfigException: Attempt to set metadata refresh timeout [55000] to be longer than sampling period`. The chart default is 120000.
* `zookeeper.connect` and `zookeeper.security.enabled` are not needed. A Kafka KRaft cluster works without them, and a leftover `zookeeper.connect: false` is ignored (3.1.0 only logs it among the unused configurations).
* `env.JAVA_OPTS` is not read by the start script. Use `env.KAFKA_HEAP_OPTS` and `env.KAFKA_JVM_PERFORMANCE_OPTS`.
* **BREAKING: the default UI is now the new one, without login.** `ui.flavor` defaults to `new`, `ui.image` is the new UI (`1.0.0`) and the legacy UI lives in `ui.legacy.image`. If you pinned `ui.image.tag: 0.4.0`, remove it and set `ui.flavor: legacy` instead (and `ui.legacy.image.tag` if you need another legacy tag); otherwise the new UI would start with a `0.4.0` tag that belongs to the old one and the pod would not start. `ghcr.io/devops-ia/kafka-cruise-control-ui:0.4.0` is the old UI and will not be updated.
* The new UI listens on the same port (`ui.service.targetPort`, 8080) but its health path is `/healthz` instead of `/health`, and it does not use the nginx ConfigMap. The `/<cluster>/kafkacruisecontrol/` paths of the old nginx proxy do not exist: the new UI picks the cluster in the page.
* The UI image tag no longer falls back to the server `appVersion`; the legacy flavor falls back to `0.4.0`.
* `ui.env` together with `ui.envFromConfigMap` or `ui.envFromSecrets` rendered two `env:` keys in the UI Deployment, so only the last one took effect. It is now one `env:` list.

## User interface

The chart deploys one UI Deployment. `ui.flavor` picks which UI it runs.

| | `new` (default) | `legacy` |
|-|-----------------|----------|
| Image | `ui.image`, `ghcr.io/devops-ia/kafka-cruise-control-ui:1.0.0` | `ui.legacy.image`, `ghcr.io/devops-ia/kafka-cruise-control-ui:0.4.0` |
| What it is | [kafka-cruise-control-ui](https://github.com/devops-ia/kafka-cruise-control-ui): Go server with the SPA embedded and its own proxy, no nginx | The LinkedIn [cruise-control-ui](https://github.com/linkedin/cruise-control-ui) behind nginx, frozen |
| Configuration | `CCUI_*` environment variables the chart generates from `clusters` | `nginx.conf` and `config.csv` in a ConfigMap (`<release>-cruise-control-ui-config`) |
| Health path | `/healthz` | `/health` |
| Login | `ui.auth.mode`: `none` (default), `local`, `oidc` | None |

The legacy UI is not rebuilt any more and gets no new tags. To build it locally, use `docker build --target legacy -t cruise-control-ui-legacy .` in [kafka-cruise-control-ui](https://github.com/devops-ia/kafka-cruise-control-ui). To go back to it: `--set ui.flavor=legacy`.

### Generated configuration (flavor `new`)

For each entry of `clusters` the chart sets `CCUI_CLUSTERS__<n>__NAME`, `__GROUP` (the `group` value, or `cluster`) and `__URL` (`http://<release>-cruise-control-<cluster>:<service.port>/kafkacruisecontrol`). It also sets `CCUI_AUTH_MODE` from `ui.auth.mode` and `CCUI_LISTEN` from `ui.service.targetPort`. Nothing else: timeouts and cluster authentication use the server defaults.

`<n>` is the position of the cluster in alphabetical order of its name, starting at 0. If you add a cluster whose name sorts before an existing one, the indexes shift, and so do any `CCUI_CLUSTERS__<n>__AUTH_*` variables you set for the later clusters (see [the UI configuration](https://github.com/devops-ia/kafka-cruise-control-ui/blob/main/docs/CONFIGURATION.md)).

Pass everything else through `ui.env` (plain values), `ui.envFromSecrets` / `ui.envFromConfigMap` (single keys) and `ui.envFromFiles` (a whole Secret or ConfigMap, as `envFrom`). A variable you define in `ui.env`, `ui.envFromSecrets` or `ui.envFromConfigMap` replaces the generated one of the same name. A Secret loaded with `envFromFiles` cannot: Kubernetes gives `env` priority over `envFrom`, so change `CCUI_AUTH_MODE` only with `ui.auth.mode` or `ui.env`. The chart sets `enableServiceLinks: false` on the pod, because the UI rejects any unknown `CCUI_*` variable and Kubernetes would inject `CCUI_*_SERVICE_HOST` for a Service whose name starts with `ccui`.

Changes to clusters, `ui.auth.mode` or `ui.env` change the pod template, so `helm upgrade` restarts the pods. A Secret you reference with `envFromFiles` or `envFromSecrets` is not tracked: run `kubectl rollout restart` after you change it.

### Login

`ui.auth.mode` defaults to `none`: **there is no login, everyone who reaches the UI is admin and can start rebalances.** The Service is `ClusterIP` and the ingress is off by default. Turn on `local` or `oidc` before you expose the UI. The chart does not create users, hashes, session secrets or OIDC providers; you provide them.

Local users. Create the hash and the Secret yourself:

```console
kubectl create secret generic ccui-secrets \
  --from-literal=CCUI_SESSION_SECRET="$(openssl rand -base64 48)" \
  --from-literal=CCUI_LOCAL_ADMIN_PASSWORD_HASH="$(htpasswd -bnBC 12 "" 'your password' | tr -d ':\n')"
```

```yaml
ui:
  auth:
    mode: local
  envFromFiles:
    - secretRef:
        name: ccui-secrets
  # Only on plain HTTP; remove it behind HTTPS
  env:
    CCUI_COOKIE_INSECURE: "true"
```

OIDC:

```yaml
ui:
  auth:
    mode: oidc
  env:
    CCUI_PUBLIC_URL: https://cc.example.com
    CCUI_OIDC__0__NAME: corp
    CCUI_OIDC__0__ISSUER: https://idp.example.com
    CCUI_OIDC__0__CLIENT_ID: cruise-control
    CCUI_OIDC__0__ADMIN_GROUPS: ccui-admins
  envFromSecrets:
    CCUI_OIDC__0__CLIENT_SECRET:
      name: ccui-oidc
      key: client-secret
    CCUI_SESSION_SECRET:
      name: ccui-oidc
      key: session-secret
```

Sessions live in the memory of each pod. With more than one replica and a login, you need session affinity: `ui.service.sessionAffinity: ClientIP` or a cookie affinity annotation on the ingress. The chart does not set it. All the `CCUI_*` variables are in the [UI configuration](https://github.com/devops-ia/kafka-cruise-control-ui/blob/main/docs/CONFIGURATION.md).

### Hardening

The new UI runs as non-root with a read-only root filesystem. The chart leaves the `securityContext` values empty, as it does for the server. A recommended setting:

```yaml
ui:
  securityContext:
    runAsNonRoot: true
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: [ALL]
```

Probes are off by default (`ui.livenessProbe.enabled` and friends). When on, they call `/healthz` in the new flavor and `/health` in the legacy one.

## Prerequisites

* Helm 3+

## Add repository

```console
helm repo add cruise-control https://devops-ia.github.io/helm-cruise-control
helm repo update
```

## Install Helm chart (repository mode)

```console
helm install [RELEASE_NAME] cruise-control/cruise-control
```

This install all the Kubernetes components associated with the chart and creates the release.

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Install Helm chart (OCI mode)

Charts are also available in OCI format. The list of available charts can be found [here](https://github.com/devops-ia/helm-cruise-control/pkgs/container/helm-cruise-control%2Fcruise-control).

```console
helm install [RELEASE_NAME] oci://ghcr.io/devops-ia/helm-cruise-control/cruise-control --version=[version]
```

## Uninstall Helm chart

```console
helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Examples

See [examples](./examples) directory.

## Configuration

See [Customizing the chart before installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with comments:

```console
helm show values cruise-control/cruise-control
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| annotations | object | `{}` | Configure annotations on Deployment |
| args | list | `[]` | Configure args </br> Ref: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/ |
| autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling with CPU or memory utilization percentage </br> Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| clusters | object | `{"cluster-dev":{}}` | Cruise Control cluster configuration Configure multiple Kafka clusters. Each cluster will have its own Deployment, Service, and ConfigMap. Access via Ingress: https://<host>/<cluster-name>/ Example: https://cruise-control.example.com/dev/ or https://cruise-control.example.com/prod/ NOTE: Values defined here will override the corresponding values from 'clustersDefaults' Each cluster can have a 'group' field. If not specified, defaults to 'cluster' |
| clustersDefaults | object | `{"capacity":{"config":"{\n  \"brokerCapacities\":[\n    {\n      \"brokerId\": \"-1\",\n      \"capacity\": {\n        \"DISK\": \"1026\",\n        \"CPU\": \"100\",\n        \"NW_IN\": \"1000\",\n        \"NW_OUT\": \"1000\"\n      },\n      \"doc\": \"This is the default capacity. Capacity unit used for disk is in MB, cpu is in number of cores, network throughput is in KB.\"\n    }\n  ]\n}\n","type":"capacity"},"cluster":{"an.example.cluster.config":false,"min.insync.replicas":1},"config":{"anomaly.detection.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal"],"anomaly.detection.interval.ms":"10000","anomaly.notifier.class":"com.linkedin.kafka.cruisecontrol.detector.notifier.SelfHealingNotifier","bootstrap.servers":"localhost:9092","broker.metric.sample.store.topic":"__KafkaCruiseControlModelTrainingSamples","broker.metrics.window.ms":300000,"broker.sample.store.topic.partition.count":8,"client.id":"cruise-control","cluster.configs.file":"config/clusterConfigs.json","completed.cruise.control.admin.user.task.retention.time.ms":604800000,"completed.cruise.control.monitor.user.task.retention.time.ms":86400000,"completed.kafka.admin.user.task.retention.time.ms":604800000,"completed.kafka.monitor.user.task.retention.time.ms":86400000,"completed.user.task.retention.time.ms":86400000,"connections.max.idle.ms":540000,"cpu.balance.threshold":1.1,"cpu.capacity.threshold":0.7,"cpu.low.utilization.threshold":0,"default.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PotentialNwOutGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderBytesInDistributionGoal"],"default.replica.movement.strategies":["com.linkedin.kafka.cruisecontrol.executor.strategy.BaseReplicaMovementStrategy"],"demotion.history.retention.time.ms":1209600000,"disk.balance.threshold":1.1,"disk.capacity.threshold":0.8,"disk.low.utilization.threshold":0,"execution.progress.check.interval.ms":10000,"goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PotentialNwOutGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderBytesInDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.kafkaassigner.KafkaAssignerDiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.kafkaassigner.KafkaAssignerEvenRackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PreferredLeaderElectionGoal"],"hard.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal"],"intra.broker.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.IntraBrokerDiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.IntraBrokerDiskUsageDistributionGoal"],"max.active.user.tasks":5,"max.cached.completed.cruise.control.admin.user.tasks":30,"max.cached.completed.cruise.control.monitor.user.tasks":20,"max.cached.completed.kafka.admin.user.tasks":30,"max.cached.completed.kafka.monitor.user.tasks":20,"max.cached.completed.user.tasks":25,"max.num.cluster.partition.movements":1250,"max.replicas.per.broker":10000,"metric.anomaly.analyzer.metrics":["BROKER_PRODUCE_LOCAL_TIME_MS_50TH","BROKER_PRODUCE_LOCAL_TIME_MS_999TH","BROKER_CONSUMER_FETCH_LOCAL_TIME_MS_50TH","BROKER_CONSUMER_FETCH_LOCAL_TIME_MS_999TH","BROKER_FOLLOWER_FETCH_LOCAL_TIME_MS_50TH","BROKER_FOLLOWER_FETCH_LOCAL_TIME_MS_999TH","BROKER_LOG_FLUSH_TIME_MS_50TH","BROKER_LOG_FLUSH_TIME_MS_999TH"],"metric.anomaly.detection.interval.ms":120000,"metric.anomaly.finder.class":"com.linkedin.kafka.cruisecontrol.detector.KafkaMetricAnomalyFinder","metric.anomaly.percentile.lower.threshold":10,"metric.anomaly.percentile.upper.threshold":90,"metric.sampler.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.prometheus.PrometheusMetricSampler","metric.sampler.partition.assignor.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.DefaultMetricSamplerPartitionAssignor","metric.sampling.interval.ms":120000,"min.samples.per.broker.metrics.window":1,"min.samples.per.partition.metrics.window":1,"min.valid.partition.ratio":0.95,"network.inbound.balance.threshold":1.1,"network.inbound.capacity.threshold":0.8,"network.inbound.low.utilization.threshold":0,"network.outbound.balance.threshold":1.1,"network.outbound.capacity.threshold":0.8,"network.outbound.low.utilization.threshold":0,"num.broker.metrics.windows":20,"num.concurrent.intra.broker.partition.movements":2,"num.concurrent.leader.movements":1000,"num.concurrent.partition.movements.per.broker":5,"num.partition.metrics.windows":5,"num.proposal.precompute.threads":1,"num.sample.loading.threads":8,"partition.metric.sample.store.topic":"__KafkaCruiseControlPartitionMetricSamples","partition.metrics.window.ms":300000,"partition.sample.store.topic.partition.count":8,"prometheus.server.endpoint":"thanos-query.prometheus:9090","proposal.expiration.ms":60000,"removal.history.retention.time.ms":1209600000,"replica.count.balance.threshold":1.1,"replica.movement.strategies":["com.linkedin.kafka.cruisecontrol.executor.strategy.PostponeUrpReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeLargeReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeSmallReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeMinIsrWithOfflineReplicasStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeOneAboveMinIsrWithOfflineReplicasStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.BaseReplicaMovementStrategy"],"sample.store.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.KafkaSampleStore","sample.store.topic.replication.factor":2,"sampling.allow.cpu.capacity.estimation":true,"self.healing.disk.failure.enabled":false,"self.healing.enabled":false,"self.healing.exclude.recently.demoted.brokers":true,"self.healing.exclude.recently.removed.brokers":true,"self.healing.goal.violation.enabled":false,"self.healing.maintenance.event.enabled":false,"self.healing.metric.anomaly.enabled":false,"self.healing.topic.anomaly.enabled":false,"topic.anomaly.finder.class":"com.linkedin.kafka.cruisecontrol.detector.TopicReplicationFactorAnomalyFinder","topic.config.provider.class":"com.linkedin.kafka.cruisecontrol.config.KafkaAdminTopicConfigProvider","topics.excluded.from.partition.movement":"__consumer_offsets.*|__amazon_msk_canary.*|__amazon_msk_connect.*|__KafkaCruiseControl.*","two.step.purgatory.max.requests":25,"two.step.purgatory.retention.time.ms":1209600000,"two.step.verification.enabled":false,"vertx.enabled":false,"webserver.accesslog.enabled":true,"webserver.api.urlprefix":"/kafkacruisecontrol/*","webserver.http.address":"0.0.0.0","webserver.http.cors.enabled":false,"webserver.http.port":9090,"webserver.request.maxBlockTimeMs":10000,"webserver.session.maxExpiryTimeMs":60000,"webserver.session.path":"/","webserver.ui.diskpath":"./cruise-control-ui/dist/","webserver.ui.urlprefix":"/*"},"jaas":{"config":"// Enter appropriate Client entry for secured zookeeper client connections\nClient {\n  com.sun.security.auth.module.Krb5LoginModule required\n  useKeyTab=true\n  keyTab=\"/path/to/zookeeper_client.keytab\"\n  storeKey=true\n  useTicketCache=false\n  principal=\"zookeeper_client@<REALM>\";\n};\n\n// Enter appropriate KafkaClient entry if using the SASL protocol, remove if not\nKafkaClient {\n  com.sun.security.auth.module.Krb5LoginModule required\n  useKeyTab=true\n  keyTab=\"/path/to/kafka_client.keytab\"\n  storeKey=true\n  useTicketCache=false\n  serviceName=\"kafka\"\n  principal=\"kafka_client@<REALM>\";\n};\n","enabled":false,"existingSecret":{"key":"cruise_control_jaas.conf","name":""}},"log4j":{"appender.console.layout.pattern":"[%d] %p %m (%c)%n","appender.console.layout.type":"PatternLayout","appender.console.name":"STDOUT","appender.console.type":"Console","appender.kafkaCruiseControlAppender.fileName":"${filename}/kafkacruisecontrol.log","appender.kafkaCruiseControlAppender.filePattern":"${filename}/kafkacruisecontrol.log.%d{yyyy-MM-dd-HH}","appender.kafkaCruiseControlAppender.layout.pattern":"[%d] %p %m (%c)%n","appender.kafkaCruiseControlAppender.layout.type":"PatternLayout","appender.kafkaCruiseControlAppender.name":"kafkaCruiseControlFile","appender.kafkaCruiseControlAppender.policies.time.interval":1,"appender.kafkaCruiseControlAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.kafkaCruiseControlAppender.policies.type":"Policies","appender.kafkaCruiseControlAppender.type":"RollingFile","appender.operationAppender.fileName":"${filename}/kafkacruisecontrol-operation.log","appender.operationAppender.filePattern":"${filename}/kafkacruisecontrol-operation.log.%d{yyyy-MM-dd}","appender.operationAppender.layout.pattern":"[%d] %p [%c] %m %n","appender.operationAppender.layout.type":"PatternLayout","appender.operationAppender.name":"operationFile","appender.operationAppender.policies.time.interval":1,"appender.operationAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.operationAppender.policies.type":"Policies","appender.operationAppender.type":"RollingFile","appender.requestAppender.fileName":"${filename}/kafkacruisecontrol-request.log","appender.requestAppender.filePattern":"${filename}/kafkacruisecontrol-request.log.%d{yyyy-MM-dd-HH}","appender.requestAppender.layout.pattern":"[%d] %p %m (%c)%n","appender.requestAppender.layout.type":"PatternLayout","appender.requestAppender.name":"requestFile","appender.requestAppender.policies.time.interval":1,"appender.requestAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.requestAppender.policies.type":"Policies","appender.requestAppender.type":"RollingFile","appenders":"console, kafkaCruiseControlAppender, operationAppender, requestAppender","logger.CruiseControlPublicAccessLogger.appenderRef.requestAppender.ref":"requestFile","logger.CruiseControlPublicAccessLogger.level":"info","logger.CruiseControlPublicAccessLogger.name":"CruiseControlPublicAccessLogger","logger.cruisecontrol.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","logger.cruisecontrol.level":"info","logger.cruisecontrol.name":"com.linkedin.kafka.cruisecontrol","logger.detector.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","logger.detector.level":"info","logger.detector.name":"com.linkedin.kafka.cruisecontrol.detector","logger.operationLogger.appenderRef.operationAppender.ref":"operationFile","logger.operationLogger.level":"info","logger.operationLogger.name":"operationLogger","property.filename":"./logs","rootLogger.appenderRef.console.ref":"STDOUT","rootLogger.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","rootLogger.appenderRefs":"console, kafkaCruiseControlAppender","rootLogger.level":"INFO"}}` | Cruise Control default cluster configuration Example:   clustersDefaults:     config:       bootstrap.servers: "localhost:9092"       self.healing.enabled: false   clusters:     dev: {}  # Inherits all from clustersDefaults     prod:       config:         bootstrap.servers: "kafka-prod:9092"  # Override         self.healing.enabled: true            # Override       # All other config values are inherited from clustersDefaults |
| clustersDefaults.capacity | object | `{"config":"{\n  \"brokerCapacities\":[\n    {\n      \"brokerId\": \"-1\",\n      \"capacity\": {\n        \"DISK\": \"1026\",\n        \"CPU\": \"100\",\n        \"NW_IN\": \"1000\",\n        \"NW_OUT\": \"1000\"\n      },\n      \"doc\": \"This is the default capacity. Capacity unit used for disk is in MB, cpu is in number of cores, network throughput is in KB.\"\n    }\n  ]\n}\n","type":"capacity"}` | Cruise Control cluster resources |
| clustersDefaults.cluster | object | `{"an.example.cluster.config":false,"min.insync.replicas":1}` | Cruise Control cluster config Sample: https://github.com/cruise-control-for-kafka/cruise-control/blob/main/config/clusterConfigs.json |
| clustersDefaults.config | object | `{"anomaly.detection.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal"],"anomaly.detection.interval.ms":"10000","anomaly.notifier.class":"com.linkedin.kafka.cruisecontrol.detector.notifier.SelfHealingNotifier","bootstrap.servers":"localhost:9092","broker.metric.sample.store.topic":"__KafkaCruiseControlModelTrainingSamples","broker.metrics.window.ms":300000,"broker.sample.store.topic.partition.count":8,"client.id":"cruise-control","cluster.configs.file":"config/clusterConfigs.json","completed.cruise.control.admin.user.task.retention.time.ms":604800000,"completed.cruise.control.monitor.user.task.retention.time.ms":86400000,"completed.kafka.admin.user.task.retention.time.ms":604800000,"completed.kafka.monitor.user.task.retention.time.ms":86400000,"completed.user.task.retention.time.ms":86400000,"connections.max.idle.ms":540000,"cpu.balance.threshold":1.1,"cpu.capacity.threshold":0.7,"cpu.low.utilization.threshold":0,"default.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PotentialNwOutGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderBytesInDistributionGoal"],"default.replica.movement.strategies":["com.linkedin.kafka.cruisecontrol.executor.strategy.BaseReplicaMovementStrategy"],"demotion.history.retention.time.ms":1209600000,"disk.balance.threshold":1.1,"disk.capacity.threshold":0.8,"disk.low.utilization.threshold":0,"execution.progress.check.interval.ms":10000,"goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PotentialNwOutGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderBytesInDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.kafkaassigner.KafkaAssignerDiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.kafkaassigner.KafkaAssignerEvenRackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PreferredLeaderElectionGoal"],"hard.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal"],"intra.broker.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.IntraBrokerDiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.IntraBrokerDiskUsageDistributionGoal"],"max.active.user.tasks":5,"max.cached.completed.cruise.control.admin.user.tasks":30,"max.cached.completed.cruise.control.monitor.user.tasks":20,"max.cached.completed.kafka.admin.user.tasks":30,"max.cached.completed.kafka.monitor.user.tasks":20,"max.cached.completed.user.tasks":25,"max.num.cluster.partition.movements":1250,"max.replicas.per.broker":10000,"metric.anomaly.analyzer.metrics":["BROKER_PRODUCE_LOCAL_TIME_MS_50TH","BROKER_PRODUCE_LOCAL_TIME_MS_999TH","BROKER_CONSUMER_FETCH_LOCAL_TIME_MS_50TH","BROKER_CONSUMER_FETCH_LOCAL_TIME_MS_999TH","BROKER_FOLLOWER_FETCH_LOCAL_TIME_MS_50TH","BROKER_FOLLOWER_FETCH_LOCAL_TIME_MS_999TH","BROKER_LOG_FLUSH_TIME_MS_50TH","BROKER_LOG_FLUSH_TIME_MS_999TH"],"metric.anomaly.detection.interval.ms":120000,"metric.anomaly.finder.class":"com.linkedin.kafka.cruisecontrol.detector.KafkaMetricAnomalyFinder","metric.anomaly.percentile.lower.threshold":10,"metric.anomaly.percentile.upper.threshold":90,"metric.sampler.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.prometheus.PrometheusMetricSampler","metric.sampler.partition.assignor.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.DefaultMetricSamplerPartitionAssignor","metric.sampling.interval.ms":120000,"min.samples.per.broker.metrics.window":1,"min.samples.per.partition.metrics.window":1,"min.valid.partition.ratio":0.95,"network.inbound.balance.threshold":1.1,"network.inbound.capacity.threshold":0.8,"network.inbound.low.utilization.threshold":0,"network.outbound.balance.threshold":1.1,"network.outbound.capacity.threshold":0.8,"network.outbound.low.utilization.threshold":0,"num.broker.metrics.windows":20,"num.concurrent.intra.broker.partition.movements":2,"num.concurrent.leader.movements":1000,"num.concurrent.partition.movements.per.broker":5,"num.partition.metrics.windows":5,"num.proposal.precompute.threads":1,"num.sample.loading.threads":8,"partition.metric.sample.store.topic":"__KafkaCruiseControlPartitionMetricSamples","partition.metrics.window.ms":300000,"partition.sample.store.topic.partition.count":8,"prometheus.server.endpoint":"thanos-query.prometheus:9090","proposal.expiration.ms":60000,"removal.history.retention.time.ms":1209600000,"replica.count.balance.threshold":1.1,"replica.movement.strategies":["com.linkedin.kafka.cruisecontrol.executor.strategy.PostponeUrpReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeLargeReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeSmallReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeMinIsrWithOfflineReplicasStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeOneAboveMinIsrWithOfflineReplicasStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.BaseReplicaMovementStrategy"],"sample.store.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.KafkaSampleStore","sample.store.topic.replication.factor":2,"sampling.allow.cpu.capacity.estimation":true,"self.healing.disk.failure.enabled":false,"self.healing.enabled":false,"self.healing.exclude.recently.demoted.brokers":true,"self.healing.exclude.recently.removed.brokers":true,"self.healing.goal.violation.enabled":false,"self.healing.maintenance.event.enabled":false,"self.healing.metric.anomaly.enabled":false,"self.healing.topic.anomaly.enabled":false,"topic.anomaly.finder.class":"com.linkedin.kafka.cruisecontrol.detector.TopicReplicationFactorAnomalyFinder","topic.config.provider.class":"com.linkedin.kafka.cruisecontrol.config.KafkaAdminTopicConfigProvider","topics.excluded.from.partition.movement":"__consumer_offsets.*|__amazon_msk_canary.*|__amazon_msk_connect.*|__KafkaCruiseControl.*","two.step.purgatory.max.requests":25,"two.step.purgatory.retention.time.ms":1209600000,"two.step.verification.enabled":false,"vertx.enabled":false,"webserver.accesslog.enabled":true,"webserver.api.urlprefix":"/kafkacruisecontrol/*","webserver.http.address":"0.0.0.0","webserver.http.cors.enabled":false,"webserver.http.port":9090,"webserver.request.maxBlockTimeMs":10000,"webserver.session.maxExpiryTimeMs":60000,"webserver.session.path":"/","webserver.ui.diskpath":"./cruise-control-ui/dist/","webserver.ui.urlprefix":"/*"}` | Cruise Control configuration Ref: https://github.com/cruise-control-for-kafka/cruise-control/wiki/Configurations |
| clustersDefaults.jaas | object | `{"config":"// Enter appropriate Client entry for secured zookeeper client connections\nClient {\n  com.sun.security.auth.module.Krb5LoginModule required\n  useKeyTab=true\n  keyTab=\"/path/to/zookeeper_client.keytab\"\n  storeKey=true\n  useTicketCache=false\n  principal=\"zookeeper_client@<REALM>\";\n};\n\n// Enter appropriate KafkaClient entry if using the SASL protocol, remove if not\nKafkaClient {\n  com.sun.security.auth.module.Krb5LoginModule required\n  useKeyTab=true\n  keyTab=\"/path/to/kafka_client.keytab\"\n  storeKey=true\n  useTicketCache=false\n  serviceName=\"kafka\"\n  principal=\"kafka_client@<REALM>\";\n};\n","enabled":false,"existingSecret":{"key":"cruise_control_jaas.conf","name":""}}` | Cruise Control JAAS configuration Sample: https://github.com/cruise-control-for-kafka/cruise-control/blob/main/config/cruise_control_jaas.conf_template |
| clustersDefaults.jaas.existingSecret | object | `{"key":"cruise_control_jaas.conf","name":""}` | Mount the JAAS file from an existing Secret instead of rendering `config` into the ConfigMap. Usually set per cluster. |
| clustersDefaults.jaas.existingSecret.key | string | `"cruise_control_jaas.conf"` | Secret key holding the JAAS file |
| clustersDefaults.jaas.existingSecret.name | string | `""` | Secret name. Empty renders `config` into the ConfigMap |
| clustersDefaults.log4j | object | `{"appender.console.layout.pattern":"[%d] %p %m (%c)%n","appender.console.layout.type":"PatternLayout","appender.console.name":"STDOUT","appender.console.type":"Console","appender.kafkaCruiseControlAppender.fileName":"${filename}/kafkacruisecontrol.log","appender.kafkaCruiseControlAppender.filePattern":"${filename}/kafkacruisecontrol.log.%d{yyyy-MM-dd-HH}","appender.kafkaCruiseControlAppender.layout.pattern":"[%d] %p %m (%c)%n","appender.kafkaCruiseControlAppender.layout.type":"PatternLayout","appender.kafkaCruiseControlAppender.name":"kafkaCruiseControlFile","appender.kafkaCruiseControlAppender.policies.time.interval":1,"appender.kafkaCruiseControlAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.kafkaCruiseControlAppender.policies.type":"Policies","appender.kafkaCruiseControlAppender.type":"RollingFile","appender.operationAppender.fileName":"${filename}/kafkacruisecontrol-operation.log","appender.operationAppender.filePattern":"${filename}/kafkacruisecontrol-operation.log.%d{yyyy-MM-dd}","appender.operationAppender.layout.pattern":"[%d] %p [%c] %m %n","appender.operationAppender.layout.type":"PatternLayout","appender.operationAppender.name":"operationFile","appender.operationAppender.policies.time.interval":1,"appender.operationAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.operationAppender.policies.type":"Policies","appender.operationAppender.type":"RollingFile","appender.requestAppender.fileName":"${filename}/kafkacruisecontrol-request.log","appender.requestAppender.filePattern":"${filename}/kafkacruisecontrol-request.log.%d{yyyy-MM-dd-HH}","appender.requestAppender.layout.pattern":"[%d] %p %m (%c)%n","appender.requestAppender.layout.type":"PatternLayout","appender.requestAppender.name":"requestFile","appender.requestAppender.policies.time.interval":1,"appender.requestAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.requestAppender.policies.type":"Policies","appender.requestAppender.type":"RollingFile","appenders":"console, kafkaCruiseControlAppender, operationAppender, requestAppender","logger.CruiseControlPublicAccessLogger.appenderRef.requestAppender.ref":"requestFile","logger.CruiseControlPublicAccessLogger.level":"info","logger.CruiseControlPublicAccessLogger.name":"CruiseControlPublicAccessLogger","logger.cruisecontrol.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","logger.cruisecontrol.level":"info","logger.cruisecontrol.name":"com.linkedin.kafka.cruisecontrol","logger.detector.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","logger.detector.level":"info","logger.detector.name":"com.linkedin.kafka.cruisecontrol.detector","logger.operationLogger.appenderRef.operationAppender.ref":"operationFile","logger.operationLogger.level":"info","logger.operationLogger.name":"operationLogger","property.filename":"./logs","rootLogger.appenderRef.console.ref":"STDOUT","rootLogger.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","rootLogger.appenderRefs":"console, kafkaCruiseControlAppender","rootLogger.level":"INFO"}` | Cruise Control log4j configuration |
| command | list | `[]` | Configure command </br> Ref: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/ |
| configMaps | list | `[]` | ConfigMap values to create configuration files Generate ConfigMap with following name: <release-name>-<name> </br> Ref: https://kubernetes.io/docs/concepts/configuration/configmap/ |
| dnsConfig | object | `{}` | Configure DNS </br> Ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/ |
| dnsPolicy | string | `"ClusterFirst"` | Configure DNS policy Options: ClusterFirst, Default, ClusterFirstWithHostNet, None </br> Ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/ |
| env | object | `{}` | Environment variables to configure application The start script reads KAFKA_HEAP_OPTS (default -Xmx1G), KAFKA_JVM_PERFORMANCE_OPTS and KAFKA_OPTS. JAVA_OPTS is not read. |
| envFromConfigMap | object | `{}` | Variables from configMap |
| envFromFiles | list | `[]` | Variables from files managed by you </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables |
| envFromSecrets | object | `{}` | Variables from secrets |
| fullnameOverride | string | `""` | String to fully override cruise-control.fullname template |
| hostAliases | list | `[]` | Configure hostAliases </br> Ref: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/ |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control","tag":""}` | Image registry The image configuration for the base service. The default image is built from https://github.com/devops-ia/kafka-cruise-control. Tags follow jdk<N>-cc<version>-iam<version>; JDK 17 (default) and 21 are published, JDK 25 is not. |
| imagePullSecrets | list | `[]` | Specifies the secrets to use for pulling images from private registries Leave empty if no secrets are required E.g. imagePullSecrets:   - name: myRegistryKeySecretName |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration to expose app </br> Ref: https://kubernetes.io/docs/concepts/services-networking/ingress/ When multiple clusters are configured, the Ingress will point to the reverse-proxy service For single cluster, it will point directly to the cluster service |
| initContainers | list | `[]` | Configure additional containers </br> Ref: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/ |
| labels | object | `{}` | Configure labels on Deployment |
| lifecycle | object | `{}` | Configure lifecycle hooks </br> Ref: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/ </br> Ref: https://learnk8s.io/graceful-shutdown |
| livenessProbe | object | `{"enabled":false,"failureThreshold":3,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure liveness checker </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| livenessProbeCustom | object | `{}` | Custom livenessProbe |
| logsVolume | object | `{}` | Volume mounted at /cruise-control/logs (any Kubernetes volume source) Empty means an emptyDir, which is writable by any uid. With a block volume (e.g. EBS gp3) set `podSecurityContext.fsGroup: 65534` so the image user can write to it. Prefer `ephemeral` over a fixed PVC: each cluster and replica gets its own ReadWriteOnce volume. </br> Ref: https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes |
| nameOverride | string | `""` | String to partially override cruise-control.fullname template (will maintain the release name) |
| networkPolicy | object | `{"egress":[],"enabled":false,"ingress":[],"policyTypes":[]}` | NetworkPolicy configuration </br> Ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| networkPolicy.enabled | bool | `false` | Enable or disable NetworkPolicy |
| networkPolicy.policyTypes | list | `[]` | Policy types |
| nodeSelector | object | `{}` | Node labels for pod assignment </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector |
| podAnnotations | object | `{}` | Configure annotations on Pods |
| podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":1,"minAvailable":null}` | Pod Disruption Budget </br> Ref: https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/pod-disruption-budget-v1/ |
| podLabels | object | `{}` | Configure labels on Pods |
| podSecurityContext | object | `{}` | Defines privilege and access control settings for a Pod </br> Ref: https://kubernetes.io/docs/concepts/security/pod-security-standards/ </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| readinessProbe | object | `{"enabled":false,"failureThreshold":3,"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Configure readinessProbe checker </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| readinessProbeCustom | object | `{}` | Custom readinessProbe |
| replicaCount | int | `1` | Number of replicas Specifies the number of replicas for the service |
| resources | object | `{}` | Resources limits and requested </br> Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| secrets | list | `[]` | Secrets values to create credentials and reference by envFromSecrets Generate Secret with following name: <release-name>-<name> </br> Ref: https://kubernetes.io/docs/concepts/configuration/secret/ |
| securityContext | object | `{}` | Defines privilege and access control settings for a Container </br> Ref: https://kubernetes.io/docs/concepts/security/pod-security-standards/ </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| service | object | `{"annotations":{},"appProtocol":"HTTP","extraPorts":[],"labels":{},"loadBalancer":{},"port":80,"portName":"http","protocol":"TCP","targetPort":9090,"type":"ClusterIP"}` | Kubernetes service to expose Pod </br> Ref: https://kubernetes.io/docs/concepts/services-networking/service/ |
| service.annotations | object | `{}` | Annotations for the service |
| service.appProtocol | string | `"HTTP"` | Application protocol (HTTP, HTTPS, etc.) |
| service.extraPorts | list | `[]` | Pod extra ports |
| service.labels | object | `{}` | Additional labels for the service |
| service.loadBalancer | object | `{}` | LoadBalancer specific configuration |
| service.port | int | `80` | Kubernetes Service port |
| service.portName | string | `"http"` | Name for the service port |
| service.protocol | string | `"TCP"` | Protocol for the service port |
| service.targetPort | int | `9090` | Pod expose port |
| service.type | string | `"ClusterIP"` | Kubernetes Service type. Allowed values: NodePort, LoadBalancer, ClusterIP, ExternalName |
| serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Enable creation of ServiceAccount </br> Ref: https://kubernetes.io/docs/concepts/security/service-accounts/ |
| startupProbe | object | `{"enabled":false,"failureThreshold":30,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure startupProbe checker </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| startupProbeCustom | object | `{}` | Custom startupProbe |
| strategy | object | `{}` | Configure strategy for the deployment |
| terminationGracePeriodSeconds | int | `30` | Configure Pod termination grace period </br> Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination |
| testConnection | object | `{"enabled":false,"repository":"busybox","tag":""}` | Enable or disable test connection |
| tolerations | list | `[]` | Tolerations for pod assignment </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| topologySpreadConstraints | list | `[]` | Control how Pods are spread across your cluster </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#example-multiple-topologyspreadconstraints |
| ui | object | `{"affinity":{},"annotations":{},"args":[],"auth":{"mode":"none"},"autoscaling":{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80},"command":[],"configMaps":[],"dnsConfig":{},"dnsPolicy":"ClusterFirst","enabled":true,"env":{},"envFromConfigMap":{},"envFromFiles":[],"envFromSecrets":{},"flavor":"new","gateway":{"annotations":{},"className":"","create":false,"enabled":false,"filters":[],"hostnames":[],"labels":{},"listeners":[{"name":"http","port":80,"protocol":"HTTP"}],"parentRefs":[{"name":"","namespace":""}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]},"hostAliases":[],"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control-ui","tag":"1.0.0"},"imagePullSecrets":[],"ingress":{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]},"initContainers":[],"labels":{},"legacy":{"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control-ui","tag":"0.4.0"}},"lifecycle":{},"livenessProbe":{"enabled":false,"failureThreshold":3,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"livenessProbeCustom":{},"networkPolicy":{"egress":[],"enabled":false,"ingress":[],"policyTypes":[]},"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false,"maxUnavailable":1,"minAvailable":null},"podLabels":{},"podSecurityContext":{},"readinessProbe":{"enabled":false,"failureThreshold":3,"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1},"readinessProbeCustom":{},"replicaCount":1,"resources":{},"secrets":[],"securityContext":{},"service":{"annotations":{},"appProtocol":"HTTP","extraPorts":[],"labels":{},"loadBalancer":{},"port":80,"portName":"http","protocol":"TCP","targetPort":8080,"type":"ClusterIP"},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"enabled":false,"failureThreshold":30,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5},"startupProbeCustom":{},"strategy":{},"terminationGracePeriodSeconds":30,"tolerations":[],"topologySpreadConstraints":[],"volumeMounts":[],"volumes":[]}` | UI configuration for multi-cluster setup This is only deployed when multiple clusters are configured It includes the Cruise Control UI with nginx acting as reverse proxy routing traffic to each cluster based on URL path |
| ui.affinity | object | `{}` | Affinity for pod assignment </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| ui.annotations | object | `{}` | Configure annotations on Deployment |
| ui.args | list | `[]` | Configure args </br> Ref: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/ |
| ui.auth | object | `{"mode":"none"}` | Authentication of the new UI (ignored by the legacy flavor) |
| ui.auth.mode | string | `"none"` | Login mode, sets CCUI_AUTH_MODE. Allowed values: none, local, oidc </br> `none` has no login: anyone who reaches the UI is admin. The chart does not create users, hashes, session secrets or OIDC providers, pass them with `ui.env`, `ui.envFromSecrets` and `ui.envFromFiles` |
| ui.autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling with CPU or memory utilization percentage </br> Ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| ui.command | list | `[]` | Configure command </br> Ref: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/ |
| ui.configMaps | list | `[]` | ConfigMap values to create configuration files Generate ConfigMap with following name: <release-name>-<name> </br> Ref: https://kubernetes.io/docs/concepts/configuration/configmap/ |
| ui.dnsConfig | object | `{}` | Configure DNS </br> Ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/ |
| ui.dnsPolicy | string | `"ClusterFirst"` | Configure DNS policy Options: ClusterFirst, Default, ClusterFirstWithHostNet, None </br> Ref: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/ |
| ui.enabled | bool | `true` | Enable the UI deployment |
| ui.env | object | `{}` | Environment variables to configure application |
| ui.envFromConfigMap | object | `{}` | Variables from configMap |
| ui.envFromFiles | list | `[]` | Variables from files managed by you </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables |
| ui.envFromSecrets | object | `{}` | Variables from secrets |
| ui.flavor | string | `"new"` | UI flavor. Allowed values: new, legacy </br> `new` deploys devops-ia/kafka-cruise-control-ui (Go server, no nginx), configured with CCUI_* variables generated from `clusters` </br> `legacy` deploys the frozen LinkedIn UI behind nginx, with the nginx.conf and config.csv the chart generates |
| ui.gateway | object | `{"annotations":{},"className":"","create":false,"enabled":false,"filters":[],"hostnames":[],"labels":{},"listeners":[{"name":"http","port":80,"protocol":"HTTP"}],"parentRefs":[{"name":"","namespace":""}],"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/"}}]}]}` | Gateway API configuration (Gateway + HTTPRoute resources) </br> Ref: https://gateway-api.sigs.k8s.io/ </br> Requires Gateway API CRDs installed in the cluster. </br> TLS is configured at the Gateway listener level, not the HTTPRoute. |
| ui.hostAliases | list | `[]` | Configure hostAliases </br> Ref: https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/ |
| ui.image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control-ui","tag":"1.0.0"}` | Image of the new UI (used when flavor is new) The image configuration for the base service |
| ui.imagePullSecrets | list | `[]` | Specifies the secrets to use for pulling images from private registries Leave empty if no secrets are required E.g. imagePullSecrets:   - name: myRegistryKeySecretName |
| ui.ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration to expose app </br> Ref: https://kubernetes.io/docs/concepts/services-networking/ingress/ When multiple clusters are configured, the Ingress will point to the reverse-proxy service For single cluster, it will point directly to the cluster service |
| ui.initContainers | list | `[]` | Configure additional containers </br> Ref: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/ |
| ui.labels | object | `{}` | Configure labels on Deployment |
| ui.legacy | object | `{"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control-ui","tag":"0.4.0"}}` | Settings of the legacy UI (used when flavor is legacy) |
| ui.legacy.image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control-ui","tag":"0.4.0"}` | Image of the legacy UI. Frozen at 0.4.0, nobody publishes new tags |
| ui.legacy.image.pullPolicy | string | `"IfNotPresent"` | Pull policy of the legacy image |
| ui.legacy.image.repository | string | `"ghcr.io/devops-ia/kafka-cruise-control-ui"` | Repository of the legacy image |
| ui.legacy.image.tag | string | `"0.4.0"` | Tag of the legacy image |
| ui.lifecycle | object | `{}` | Configure lifecycle hooks </br> Ref: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/ </br> Ref: https://learnk8s.io/graceful-shutdown |
| ui.livenessProbe | object | `{"enabled":false,"failureThreshold":3,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure liveness checker </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| ui.livenessProbeCustom | object | `{}` | Custom livenessProbe |
| ui.networkPolicy | object | `{"egress":[],"enabled":false,"ingress":[],"policyTypes":[]}` | NetworkPolicy configuration </br> Ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| ui.networkPolicy.enabled | bool | `false` | Enable or disable NetworkPolicy |
| ui.networkPolicy.policyTypes | list | `[]` | Policy types |
| ui.nodeSelector | object | `{}` | Node labels for pod assignment </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector |
| ui.podAnnotations | object | `{}` | Configure annotations on Pods |
| ui.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":1,"minAvailable":null}` | Pod Disruption Budget </br> Ref: https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/pod-disruption-budget-v1/ |
| ui.podLabels | object | `{}` | Configure labels on Pods |
| ui.podSecurityContext | object | `{}` | Defines privilege and access control settings for a Pod </br> Ref: https://kubernetes.io/docs/concepts/security/pod-security-standards/ </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| ui.readinessProbe | object | `{"enabled":false,"failureThreshold":3,"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Configure readinessProbe checker </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| ui.readinessProbeCustom | object | `{}` | Custom readinessProbe |
| ui.replicaCount | int | `1` | Number of replicas Specifies the number of replicas for the service |
| ui.resources | object | `{}` | Resources limits and requested </br> Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| ui.secrets | list | `[]` | Secrets values to create credentials and reference by envFromSecrets Generate Secret with following name: <release-name>-<name> </br> Ref: https://kubernetes.io/docs/concepts/configuration/secret/ |
| ui.securityContext | object | `{}` | Defines privilege and access control settings for a Container </br> Ref: https://kubernetes.io/docs/concepts/security/pod-security-standards/ </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| ui.service | object | `{"annotations":{},"appProtocol":"HTTP","extraPorts":[],"labels":{},"loadBalancer":{},"port":80,"portName":"http","protocol":"TCP","targetPort":8080,"type":"ClusterIP"}` | Kubernetes service to expose Pod </br> Ref: https://kubernetes.io/docs/concepts/services-networking/service/ |
| ui.service.annotations | object | `{}` | Annotations for the service |
| ui.service.appProtocol | string | `"HTTP"` | Application protocol (HTTP, HTTPS, etc.) |
| ui.service.extraPorts | list | `[]` | Pod extra ports |
| ui.service.labels | object | `{}` | Additional labels for the service |
| ui.service.loadBalancer | object | `{}` | LoadBalancer specific configuration |
| ui.service.port | int | `80` | Kubernetes Service port |
| ui.service.portName | string | `"http"` | Name for the service port |
| ui.service.protocol | string | `"TCP"` | Protocol for the service port |
| ui.service.targetPort | int | `8080` | Pod expose port |
| ui.service.type | string | `"ClusterIP"` | Kubernetes Service type. Allowed values: NodePort, LoadBalancer, ClusterIP, ExternalName |
| ui.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | Enable creation of ServiceAccount </br> Ref: https://kubernetes.io/docs/concepts/security/service-accounts/ |
| ui.startupProbe | object | `{"enabled":false,"failureThreshold":30,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure startupProbe checker </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| ui.startupProbeCustom | object | `{}` | Custom startupProbe |
| ui.strategy | object | `{}` | Configure strategy for the deployment |
| ui.terminationGracePeriodSeconds | int | `30` | Configure Pod termination grace period </br> Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination |
| ui.tolerations | list | `[]` | Tolerations for pod assignment </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| ui.topologySpreadConstraints | list | `[]` | Control how Pods are spread across your cluster </br> Ref: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/#example-multiple-topologyspreadconstraints |
| ui.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| ui.volumes | list | `[]` | Additional volumes on the output Deployment definition </br> Ref: https://kubernetes.io/docs/concepts/storage/volumes/ </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ </br> Ref: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#create-a-pod-that-has-access-to-the-secret-data-through-a-volume |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition |
| volumes | list | `[]` | Additional volumes on the output Deployment definition </br> Ref: https://kubernetes.io/docs/concepts/storage/volumes/ </br> Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/ </br> Ref: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#create-a-pod-that-has-access-to-the-secret-data-through-a-volume |
