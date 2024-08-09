# cruise-control

A Helm chart to deploy Cruise Control for Apache Kafka

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| ialejandro | <hello@ialejandro.rocks> | <https://ialejandro.rocks> |

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

## Basic installation and examples

See [basic installation](docs/configuration.md) and [examples](docs/examples.md).

## Configuration

See [Customizing the chart before installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with comments:

```console
helm show values cruise-control/cruise-control
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment |
| autoscaling | object | `{"enabled":false,"maxReplicas":100,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Autoscaling with CPU or memory utilization percentage |
| config | object | `{"anomaly.detection.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal"],"anomaly.detection.interval.ms":"10000","anomaly.notifier.class":"com.linkedin.kafka.cruisecontrol.detector.notifier.SelfHealingNotifier","bootstrap.servers":"localhost:9092","broker.metric.sample.store.topic":"__KafkaCruiseControlModelTrainingSamples","broker.metrics.window.ms":300000,"broker.sample.store.topic.partition.count":8,"capacity.config.file":"config/capacityCores.json","client.id":"cruise-control","cluster.configs.file":"config/clusterConfigs.json","completed.cruise.control.admin.user.task.retention.time.ms":604800000,"completed.cruise.control.monitor.user.task.retention.time.ms":86400000,"completed.kafka.admin.user.task.retention.time.ms":604800000,"completed.kafka.monitor.user.task.retention.time.ms":86400000,"completed.user.task.retention.time.ms":86400000,"connections.max.idle.ms":540000,"cpu.balance.threshold":1.1,"cpu.capacity.threshold":0.7,"cpu.low.utilization.threshold":0,"default.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PotentialNwOutGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderBytesInDistributionGoal"],"default.replica.movement.strategies":["com.linkedin.kafka.cruisecontrol.executor.strategy.BaseReplicaMovementStrategy"],"demotion.history.retention.time.ms":1209600000,"disk.balance.threshold":1.1,"disk.capacity.threshold":0.8,"disk.low.utilization.threshold":0,"execution.progress.check.interval.ms":10000,"goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PotentialNwOutGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.LeaderBytesInDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.kafkaassigner.KafkaAssignerDiskUsageDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.kafkaassigner.KafkaAssignerEvenRackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.PreferredLeaderElectionGoal"],"hard.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.RackAwareGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.MinTopicLeadersPerBrokerGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.TopicReplicaDistributionGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.ReplicaCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.DiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkInboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.NetworkOutboundCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.CpuCapacityGoal"],"intra.broker.goals":["com.linkedin.kafka.cruisecontrol.analyzer.goals.IntraBrokerDiskCapacityGoal","com.linkedin.kafka.cruisecontrol.analyzer.goals.IntraBrokerDiskUsageDistributionGoal"],"max.active.user.tasks":5,"max.cached.completed.cruise.control.admin.user.tasks":30,"max.cached.completed.cruise.control.monitor.user.tasks":20,"max.cached.completed.kafka.admin.user.tasks":30,"max.cached.completed.kafka.monitor.user.tasks":20,"max.cached.completed.user.tasks":25,"max.num.cluster.partition.movements":1250,"max.replicas.per.broker":10000,"metric.anomaly.analyzer.metrics":["BROKER_PRODUCE_LOCAL_TIME_MS_50TH","BROKER_PRODUCE_LOCAL_TIME_MS_999TH","BROKER_CONSUMER_FETCH_LOCAL_TIME_MS_50TH","BROKER_CONSUMER_FETCH_LOCAL_TIME_MS_999TH","BROKER_FOLLOWER_FETCH_LOCAL_TIME_MS_50TH","BROKER_FOLLOWER_FETCH_LOCAL_TIME_MS_999TH","BROKER_LOG_FLUSH_TIME_MS_50TH","BROKER_LOG_FLUSH_TIME_MS_999TH"],"metric.anomaly.detection.interval.ms":120000,"metric.anomaly.finder.class":"com.linkedin.kafka.cruisecontrol.detector.KafkaMetricAnomalyFinder","metric.anomaly.percentile.lower.threshold":10,"metric.anomaly.percentile.upper.threshold":90,"metric.sampler.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.prometheus.PrometheusMetricSampler","metric.sampler.partition.assignor.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.DefaultMetricSamplerPartitionAssignor","metric.sampling.interval.ms":120000,"min.samples.per.broker.metrics.window":1,"min.samples.per.partition.metrics.window":1,"min.valid.partition.ratio":0.95,"network.inbound.balance.threshold":1.1,"network.inbound.capacity.threshold":0.8,"network.inbound.low.utilization.threshold":0,"network.outbound.balance.threshold":1.1,"network.outbound.capacity.threshold":0.8,"network.outbound.low.utilization.threshold":0,"num.broker.metrics.windows":20,"num.concurrent.intra.broker.partition.movements":2,"num.concurrent.leader.movements":1000,"num.concurrent.partition.movements.per.broker":5,"num.partition.metrics.windows":5,"num.proposal.precompute.threads":1,"num.sample.loading.threads":8,"partition.metric.sample.store.topic":"__KafkaCruiseControlPartitionMetricSamples","partition.metrics.window.ms":300000,"partition.sample.store.topic.partition.count":8,"prometheus.server.endpoint":"thanos-query.prometheus:9090","proposal.expiration.ms":60000,"removal.history.retention.time.ms":1209600000,"replica.count.balance.threshold":1.1,"replica.movement.strategies":["com.linkedin.kafka.cruisecontrol.executor.strategy.PostponeUrpReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeLargeReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeSmallReplicaMovementStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeMinIsrWithOfflineReplicasStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.PrioritizeOneAboveMinIsrWithOfflineReplicasStrategy","com.linkedin.kafka.cruisecontrol.executor.strategy.BaseReplicaMovementStrategy"],"sample.store.class":"com.linkedin.kafka.cruisecontrol.monitor.sampling.KafkaSampleStore","sample.store.topic.replication.factor":2,"sampling.allow.cpu.capacity.estimation":true,"self.healing.disk.failure.enabled":false,"self.healing.enabled":false,"self.healing.exclude.recently.demoted.brokers":true,"self.healing.exclude.recently.removed.brokers":true,"self.healing.goal.violation.enabled":false,"self.healing.maintenance.event.enabled":false,"self.healing.metric.anomaly.enabled":false,"self.healing.topic.anomaly.enabled":false,"topic.anomaly.finder.class":"com.linkedin.kafka.cruisecontrol.detector.TopicReplicationFactorAnomalyFinder","topic.config.provider.class":"com.linkedin.kafka.cruisecontrol.config.KafkaAdminTopicConfigProvider","topics.excluded.from.partition.movement":"__consumer_offsets.*|__amazon_msk_canary.*|__amazon_msk_connect.*|__KafkaCruiseControl.*","two.step.purgatory.max.requests":25,"two.step.purgatory.retention.time.ms":1209600000,"two.step.verification.enabled":false,"vertx.enabled":false,"webserver.accesslog.enabled":true,"webserver.api.urlprefix":"/kafkacruisecontrol/*","webserver.http.address":"0.0.0.0","webserver.http.cors.enabled":false,"webserver.http.port":9090,"webserver.request.maxBlockTimeMs":10000,"webserver.session.maxExpiryTimeMs":60000,"webserver.session.path":"/","webserver.ui.diskpath":"./cruise-control-ui/dist/","webserver.ui.urlprefix":"/*","zookeeper.security.enabled":false}` | Cruise Control configuration ref: https://github.com/linkedin/cruise-control/wiki/Configurations |
| fullnameOverride | string | `""` | String to fully override cruise-control.fullname template |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"ghcr.io/devops-ia/kafka-cruise-control","tag":""}` | Image registry |
| imagePullSecrets | list | `[]` | Global Docker registry secret names as an array |
| ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"chart-example.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}],"tls":[]}` | Ingress configuration to expose app |
| kafkaCluster | object | `{"networkIn":1000,"networkOut":1000,"numCores":2,"storage":1024}` | Cruise Control cluster resources |
| livenessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure liveness Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| log4j | object | `{"appender.console.layout.pattern":"[%d] %p %m (%c)%n","appender.console.layout.type":"PatternLayout","appender.console.name":"STDOUT","appender.console.type":"Console","appender.kafkaCruiseControlAppender.fileName":"${filename}/kafkacruisecontrol.log","appender.kafkaCruiseControlAppender.filePattern":"${filename}/kafkacruisecontrol.log.%d{yyyy-MM-dd-HH}","appender.kafkaCruiseControlAppender.layout.pattern":"[%d] %p %m (%c)%n","appender.kafkaCruiseControlAppender.layout.type":"PatternLayout","appender.kafkaCruiseControlAppender.name":"kafkaCruiseControlFile","appender.kafkaCruiseControlAppender.policies.time.interval":1,"appender.kafkaCruiseControlAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.kafkaCruiseControlAppender.policies.type":"Policies","appender.kafkaCruiseControlAppender.type":"RollingFile","appender.operationAppender.fileName":"${filename}/kafkacruisecontrol-operation.log","appender.operationAppender.filePattern":"${filename}/kafkacruisecontrol-operation.log.%d{yyyy-MM-dd}","appender.operationAppender.layout.pattern":"[%d] %p [%c] %m %n","appender.operationAppender.layout.type":"PatternLayout","appender.operationAppender.name":"operationFile","appender.operationAppender.policies.time.interval":1,"appender.operationAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.operationAppender.policies.type":"Policies","appender.operationAppender.type":"RollingFile","appender.requestAppender.fileName":"${filename}/kafkacruisecontrol-request.log","appender.requestAppender.filePattern":"${filename}/kafkacruisecontrol-request.log.%d{yyyy-MM-dd-HH}","appender.requestAppender.layout.pattern":"[%d] %p %m (%c)%n","appender.requestAppender.layout.type":"PatternLayout","appender.requestAppender.name":"requestFile","appender.requestAppender.policies.time.interval":1,"appender.requestAppender.policies.time.type":"TimeBasedTriggeringPolicy","appender.requestAppender.policies.type":"Policies","appender.requestAppender.type":"RollingFile","appenders":"console, kafkaCruiseControlAppender, operationAppender, requestAppender","logger.CruiseControlPublicAccessLogger.appenderRef.requestAppender.ref":"requestFile","logger.CruiseControlPublicAccessLogger.level":"info","logger.CruiseControlPublicAccessLogger.name":"CruiseControlPublicAccessLogger","logger.cruisecontrol.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","logger.cruisecontrol.level":"info","logger.cruisecontrol.name":"com.linkedin.kafka.cruisecontrol","logger.detector.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","logger.detector.level":"info","logger.detector.name":"com.linkedin.kafka.cruisecontrol.detector","logger.operationLogger.appenderRef.operationAppender.ref":"operationFile","logger.operationLogger.level":"info","logger.operationLogger.name":"operationLogger","property.filename":"./logs","rootLogger.appenderRef.console.ref":"STDOUT","rootLogger.appenderRef.kafkaCruiseControlAppender.ref":"kafkaCruiseControlFile","rootLogger.appenderRefs":"console, kafkaCruiseControlAppender","rootLogger.level":"INFO"}` | Cruise Control log4j configuration |
| nameOverride | string | `""` | String to partially override cruise-control.fullname template (will maintain the release name) |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| podAnnotations | object | `{}` | Pod annotations |
| podLabels | object | `{}` | Pod labels |
| podSecurityContext | object | `{}` | Privilege and access control settings for a Pod or Container |
| readinessProbe | object | `{"enabled":true,"failureThreshold":3,"initialDelaySeconds":10,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":1}` | Configure readinessProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| replicaCount | int | `1` | Number of replicas |
| resources | object | `{}` | The resources limits and requested |
| securityContext | object | `{}` | Privilege and access control settings |
| service | object | `{"port":80,"targetPort":4000,"type":"ClusterIP"}` | Kubernetes service to expose Pod |
| service.port | int | `80` | Kubernetes Service port |
| service.targetPort | int | `4000` | Pod expose port |
| service.type | string | `"ClusterIP"` | Kubernetes Service type. Allowed values: NodePort, LoadBalancer or ClusterIP |
| serviceAccount | object | `{"annotations":{},"automountServiceAccountToken":false,"create":true,"name":""}` | Enable creation of ServiceAccount |
| startupProbe | object | `{"enabled":true,"failureThreshold":30,"initialDelaySeconds":180,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":5}` | Configure startupProbe Ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes |
| tolerations | list | `[]` | Tolerations for pod assignment |
| volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[]` | Additional volumes on the output Deployment definition. |