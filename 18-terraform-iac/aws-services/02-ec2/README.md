# AWS EC2 — Elastic Compute Cloud

## What is EC2?

AWS's core virtual-machine service — resizable compute capacity you rent by the
second/hour instead of owning physical servers. An EC2 **instance** is one running virtual
machine: a chosen amount of CPU, memory, storage, and network throughput, booted from a
chosen OS image.

## AMI (Amazon Machine Image)

The **template** an instance boots from — a snapshot of a root filesystem plus
launch permissions and block-device mappings. AWS publishes AMIs for Amazon Linux,
Ubuntu, Windows Server, etc.; you can also create a **custom AMI** from an instance
you've configured (installed packages, baked-in app code) so every new instance launches
pre-configured instead of running a setup script on boot.

## Instance Types

A combination of CPU, memory, storage, and network performance, named like `t3.micro` or
`m5.large`:
- **Family letter** (`t`, `m`, `c`, `r`, ...) signals the optimization — `t` = burstable
  general purpose, `c` = compute-optimized, `r` = memory-optimized, `m` = balanced.
- **Generation number** (`t3` vs `t2`) — newer generations are usually cheaper and faster.
- **Size** (`micro`, `small`, `large`, `2xlarge`, ...) — scales CPU/memory together.

## Key Pairs

An SSH key pair used to log into a Linux instance (or decrypt the admin password on
Windows) — AWS stores only the **public** key on the instance at launch; the **private**
key is downloaded once at creation and never recoverable from AWS again if lost. Anyone
holding the private key can SSH in, so it's effectively a credential and needs to be
protected like one.

## Security Groups

A **stateful, instance-level virtual firewall** — a set of allow rules (no explicit deny
rules exist) controlling inbound and outbound traffic by port/protocol/source. "Stateful"
means a response to an allowed inbound request is automatically allowed back out, without
needing a matching outbound rule. An instance can have multiple security groups attached;
the effective rule set is the union of all of them.

## EBS (Elastic Block Store)

The **persistent disk** attached to an instance — unlike the instance's own lifecycle, an
EBS volume survives instance stop/start (though **not** necessarily termination, depending
on the `DeleteOnTermination` flag) and can be detached from one instance and reattached to
another. EBS volumes support point-in-time **snapshots** stored in S3, which is how AMIs
and backups are typically built.

## Public vs Private IP

- **Public IP**: reachable from the internet. Either a dynamic one assigned at launch
  (changes if the instance stops/starts) or a static **Elastic IP** that stays reserved to
  the account until released.
- **Private IP**: only reachable from inside the VPC (or over VPN/peering) — this is what
  instances actually use to talk to each other; the public IP is just a NAT mapping on top.
- A production pattern: put app servers in a **private subnet** with no public IP at all,
  reachable only through a load balancer or bastion host.

## Instance Lifecycle

```
pending → running → (stopping → stopped → pending → running)* → shutting-down → terminated
```
- **Stop/Start**: the instance's root EBS volume persists; the instance keeps its instance
  ID but usually gets a new public IP (unless using an Elastic IP).
- **Terminate**: permanent — the instance ID is gone forever, and by default its root EBS
  volume is deleted too (unless `DeleteOnTermination=false` was set).
- **Reboot**: like restarting an OS — same host, same IPs, nothing about the underlying
  instance changes.

## Common Use Cases

- Hosting a web/app server behind a Load Balancer, in an Auto Scaling Group that adds/
  removes instances based on load.
- A short-lived batch/build worker, launched for a job and terminated when it's done.
- A bastion/jump host in a public subnet, as the single controlled entry point to reach
  private-subnet instances over SSH.
- Self-managed databases or specialized software that doesn't fit a managed service like
  RDS — at the cost of then owning the OS patching, backups, and HA yourself.
