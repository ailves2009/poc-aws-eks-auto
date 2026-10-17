# modules/nginx

Demo workload for EKS Auto Mode.

| Resource                   | Notes                                                                                                   |
| -------------------------- | ------------------------------------------------------------------------------------------------------- |
| Namespace                  | Pod Security Admission `restricted` enforced                                                            |
| Deployment                 | `nginx-unprivileged` (UID 101, port 8080), read-only root FS, no capabilities, zone topology spread, `workload-tier` node selector |
| PodDisruptionBudget        | `minAvailable: 1`, so Auto Mode consolidation and node expiry never take the app down                   |
| HorizontalPodAutoscaler v2 | CPU target, fast scale-up, 5-minute scale-down stabilization; replica count is ignored by Terraform     |
| Service                    | ClusterIP; the ALB targets pod IPs directly (`target-type: ip`)                                         |
| Ingress                    | `alb` IngressClass (Auto Mode); HTTP→HTTPS redirect; external-dns publishes `var.hostname`              |

Inputs: see [variables.tf](variables.tf). Outputs: `url`, `alb_hostname`.
