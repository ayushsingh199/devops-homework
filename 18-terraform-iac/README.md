# Session 18: Terraform & Infrastructure as Code

## Task 1: Terraform S3 Demo

Full real workflow against a real (if local) S3-compatible API — not a mock, not a
dry-run — [`terraform-s3-demo/`](terraform-s3-demo). Transcript:
[`terraform-s3-demo/task1-s3-demo.txt`](terraform-s3-demo/task1-s3-demo.txt).

```bash
terraform init       # downloaded hashicorp/aws v5.100.0
terraform fmt
terraform validate   # Success! The configuration is valid.
terraform plan        # Plan: 1 to add, 0 to change, 0 to destroy.
terraform apply -auto-approve
# aws_s3_bucket.devops_demo: Creation complete after 15s [id=ayush-devops-homework-s3-demo]
terraform state list
terraform state show aws_s3_bucket.devops_demo
terraform output
# bucket_arn    = "arn:aws:s3:::ayush-devops-homework-s3-demo"
# bucket_name   = "ayush-devops-homework-s3-demo"
# bucket_region = "ap-south-1"
terraform plan -destroy
terraform destroy -auto-approve
# Destroy complete! Resources: 1 destroyed.
```

**Verified independently of Terraform's own state** — not just trusting
`terraform output`, but hitting the actual S3-compatible HTTP API directly:
```bash
curl -I http://localhost:4566/ayush-devops-homework-s3-demo
# HTTP/1.1 200 OK   <- real AWS-style response: x-amz-bucket-region, x-amz-request-id

# ... after destroy ...
curl -I http://localhost:4566/ayush-devops-homework-s3-demo
# HTTP/1.1 404 NOT FOUND   <- genuinely gone
```

## Why LocalStack instead of a real AWS account

Provisioning real AWS infrastructure needs real credentials and can incur real cost —
neither of which is appropriate to use without explicit authorization. LocalStack runs a
real, local, S3-API-compatible server in a Docker container, so every `terraform` command
above is genuinely real (real HTTP requests, a real provider plugin, a real bucket that
really gets created and destroyed) — just against `localhost:4566` instead of AWS's
actual endpoints. [`terraform-s3-demo/providers.tf`](terraform-s3-demo/providers.tf) is
the only thing that changes versus pointing at real AWS: the `endpoints` block and dummy
`test`/`test` credentials. The resource definitions, the entire Terraform workflow, and
the state management are identical either way.

**A real snag hit and fixed along the way**: `docker run localstack/localstack:latest`
failed immediately —
```
License activation failed! 🔑❌
Reason: No credentials were found in the environment.
```
LocalStack merged its Community and Pro Docker images into one starting around version
2026.03.0 — `:latest` now requires a free account + auth token just to start, even for
basic S3. Since creating an account on the user's behalf isn't something to do without
asking, and the free *tier* itself genuinely still exists (confirmed via web search), the
fix was pinning to `localstack/localstack:4.4.0` — the last release published before that
merge — which starts cleanly with zero account, zero token:
```
LocalStack version: 4.4.0
Ready.
```

## Task 2: AWS Services Research

Conceptual writeups — no infrastructure needed, just documentation:

- [`aws-services/01-iam/README.md`](aws-services/01-iam/README.md) — Users, Groups,
  Roles, Policies, least privilege
- [`aws-services/02-ec2/README.md`](aws-services/02-ec2/README.md) — AMI, instance
  types, key pairs, security groups, EBS, instance lifecycle
- [`aws-services/03-s3/README.md`](aws-services/03-s3/README.md) — buckets, objects,
  storage classes, versioning, lifecycle policies, encryption, bucket policies
- [`aws-services/04-vpc/README.md`](aws-services/04-vpc/README.md) — CIDR, subnets,
  route tables, Internet/NAT gateways, security groups vs NACLs, public vs private subnets
- [`aws-services/05-dynamodb-rds/README.md`](aws-services/05-dynamodb-rds/README.md) —
  DynamoDB (NoSQL, partition/sort keys) vs RDS (relational, Multi-AZ, read replicas)

Screenshot: [`../screenshots/17-terraform-s3.png`](../screenshots/17-terraform-s3.png)
