# AKS Observability + Incident Response Lab

## Objective

Practice a production troubleshooting workflow for AKS and Azure workloads: establish impact, collect evidence, isolate the failing layer, mitigate safely, validate recovery, and record an RCA.

## Troubleshooting flow

```text
User impact -> Scope + timeline -> Metrics/logs/events -> Request-path isolation -> Root cause -> Mitigation -> Validation -> RCA
```

## Four golden signals

- **Latency:** request duration and p95/p99 trends.
- **Traffic:** request rate or throughput.
- **Errors:** HTTP 4xx/5xx and application failures.
- **Saturation:** CPU, memory, connection pools, queue depth, and capacity.

Do not treat one CPU threshold as application health. Correlate saturation with traffic, latency, and errors.

## AKS evidence collection

Start with read-only evidence collection before changing production:

```bash
kubectl get pods -n <namespace> -o wide
kubectl get deploy -n <namespace>
kubectl get svc,endpoints -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl top pods -n <namespace>
kubectl top nodes
```

Use the output to determine whether Pods are scheduled and Ready, whether containers restart or are OOM-killed, whether Services have endpoints, and whether recent changes or resource pressure correlate with the failure.

## 503 investigation

A 503 is a symptom, not a root cause.

```text
Client -> DNS -> Front Door/App Gateway -> Ingress -> Service -> Endpoints -> Ready Pods -> Application -> Dependencies
```

Check each boundary and correlate timestamps. A Pod being `Running` does not prove it is Ready, reachable through the Service, or able to satisfy the request.

### Common checks

1. Gateway/backend health.
2. Ingress rules and controller logs.
3. Service selectors and endpoint count.
4. Readiness probes.
5. Recent rollout or configuration changes.
6. HPA behavior and node capacity.
7. Network/DNS/firewall changes.
8. Downstream dependency latency/errors.

## Restart-loop investigation

```text
Restart loop
  -> application exits?
  -> OOMKilled?
  -> liveness probe fails?
  -> configuration/dependency failure?
  -> node problem?
```

Use current and previous container logs. Capture evidence before restarting or deleting workloads.

## Alert design

Prefer alerts that represent meaningful impact and are actionable. For example, an elevated 5xx rate sustained for several minutes is generally more useful than a CPU-only alert.

Good alerts should be:

- Actionable
- Specific
- Resistant to short-lived noise
- Linked to a runbook
- Prioritized by service impact

Avoid alert fatigue by removing alerts that repeatedly fire without a clear operator action.

## Observability signals

| Signal | Main question |
|---|---|
| Logs | What happened? |
| Metrics | How much/how often? |
| Traces | Where did the request spend time? |
| Kubernetes events | What changed or failed at the platform layer? |

Correlate these signals around the same timestamp and workload/request boundary.

## Safe incident response

1. Confirm impact and affected scope.
2. Establish a timeline.
3. Stop risky rollout activity when appropriate.
4. Collect evidence.
5. Identify the smallest failing boundary.
6. Apply the lowest-risk mitigation.
7. Validate recovery with metrics and representative requests.
8. Monitor for regression.
9. Preserve evidence.
10. Complete RCA and corrective actions.

Avoid multiple unrelated production changes at once because that destroys causal evidence and increases risk.

## RCA template

```text
Impact:
Start/end time:
Affected service/environment:
Detection method:
Customer impact:
Timeline:
Root cause:
Contributing factors:
Immediate mitigation:
Resolution:
Why existing controls did not prevent/detect it:
Corrective actions:
Owner/date:
```

## Senior interview framework

For production troubleshooting, answer in this order:

**Impact -> Scope -> Timeline -> Telemetry -> Isolation -> Root cause -> Mitigation -> Validation -> Prevention**

Explain why each command, metric, or log is being checked and what decision its output enables.
