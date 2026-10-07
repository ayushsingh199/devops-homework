# Session 19: Cloud & Terraform in Action

A complete, real, end-to-end cloud infrastructure stack — not isolated resources, a
genuine dependency chain — built and torn down with Terraform against LocalStack.
Transcript: [`mini-project/task1-infra-demo.txt`](mini-project/task1-infra-demo.txt).

## Architecture

```
                         Terraform
                             │
                             ▼
                        ┌─────────┐
                        │   VPC   │  10.20.0.0/16
                        └────┬────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌─────────────┐ ┌──────────────┐
        │  Subnet  │  │   Internet  │ │   Security   │
        │10.20.1.0/│  │   Gateway   │ │    Group     │
        │   24     │  └──────┬──────┘ │ (80/443/22)  │
        └────┬─────┘         │        └──────┬───────┘
             │          ┌────▼────┐          │
             │          │  Route  │          │
             │          │  Table  │          │
             │          │0.0.0.0/0│          │
             │          └────┬────┘          │
             └───────────────┤               │
                              ▼               │
                        ┌───────────┐         │
                        │    EC2    ├─────────┘
                        │ Instance  │   (attached SG)
                        └───────────┘

                        ┌───────────┐
                        │    S3     │  (independent of the VPC —
                        │  Bucket   │   app data storage)
                        └───────────┘
```

## What each piece does, and how Terraform wired them together

| Resource | Role | Depends on |
|---|---|---|
| `aws_vpc.main` | The network boundary (`10.20.0.0/16`) | — |
| `aws_subnet.public` | A `/24` slice of the VPC, pinned to one AZ | `aws_vpc.main` |
| `aws_internet_gateway.main` | The VPC's door to the internet | `aws_vpc.main` |
| `aws_route_table.public` + `aws_route_table_association.public` | What makes the subnet *public* — routes `0.0.0.0/0` at the IGW, then attaches that route table to the subnet | both of the above |
| `aws_security_group.web` | Firewall: allows 80/443/22 in, everything out | `aws_vpc.main` |
| `aws_instance.web` | The actual compute, launched into the subnet with the security group attached | subnet + security group |
| `aws_s3_bucket.app_data` | App data storage — deliberately independent of the VPC (S3 is a global/regional service, not something that lives *inside* a VPC the way EC2 does) | — |

Terraform resolved this entire dependency graph itself from the resource references in
[`mini-project/main.tf`](mini-project/main.tf) — nowhere is there an explicit
"create X before Y" instruction; `aws_subnet.public` referencing `aws_vpc.main.id` *is*
the dependency declaration.

## The real run

```bash
terraform init      # hashicorp/aws v5.x, same provider as session18's S3 demo
terraform fmt
terraform validate
terraform plan        # Plan: 8 to add, 0 to change, 0 to destroy.
terraform apply -auto-approve
```
```text
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
Outputs:
bucket_name        = "ayush-devops-homework-session19-data"
instance_id        = "i-2826211f6957c5e89"
security_group_id  = "sg-524105f519e2b6a03"
subnet_id          = "subnet-af2ddd3007ee7dd2d"
vpc_cidr           = "10.20.0.0/16"
vpc_id             = "vpc-3c640d72475135df0"
```

**Verified independently of Terraform's own state** — every resource type genuinely
exists in LocalStack's running services, and the bucket responds for real over HTTP:
```bash
curl -s http://localhost:4566/_localstack/health | ... 
# "ec2": "running", "s3": "running"
curl -I http://localhost:4566/ayush-devops-homework-session19-data
# HTTP/1.1 200 OK
```

Then the full teardown:
```bash
terraform plan -destroy
terraform destroy -auto-approve
```
```text
Destroy complete! Resources: 8 destroyed.
```
`terraform state list` confirmed empty afterward.

## LocalStack, again

Same setup as [Session 18](../18-terraform-iac/README.md) — `localstack/localstack:4.4.0`
(the last version before LocalStack required a paid account/auth token), reused from the
already-pulled image rather than pulling it twice. EC2 in LocalStack's free/community
edition is API-level emulation: `aws_instance.web` genuinely went through
`Creating... → Still creating... → Creation complete`, got a real instance ID, and was
destroyed cleanly — the EC2 control-plane API (create, describe, terminate, state
tracking) is fully exercised, Terraform's dependency graph and lifecycle management are
fully real; only the actual guest-VM boot is not happening, which is invisible to anything
in this demo (Terraform never waits on boot completion to mark `apply` successful).

Screenshot: [`../screenshots/18-cloud-terraform.png`](../screenshots/18-cloud-terraform.png)
