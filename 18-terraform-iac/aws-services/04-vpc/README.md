# AWS VPC — Virtual Private Cloud

## What is a VPC?

A logically isolated, private network inside AWS — your own virtual datacenter's
network layer. Every resource that needs network connectivity (EC2 instances, RDS
databases, Lambda functions with VPC access) lives inside a VPC, which controls exactly
what can reach what, and what can reach the internet.

## CIDR

A VPC is defined by an **IP address range** in CIDR notation, e.g. `10.0.0.0/16` — that
`/16` means the first 16 bits are fixed (the `10.0`) and the remaining 16 bits
(65,536 addresses) are available to carve into subnets. Picking this range matters because
it can't be changed later without major surgery, and it must not overlap with any network
you'll ever need to VPN or peer with.

## Subnets

A **subdivision of the VPC's CIDR range**, tied to exactly one Availability Zone —
`10.0.1.0/24` might be AZ-a, `10.0.2.0/24` might be AZ-b. Resources launch into a specific
subnet, which is what actually determines their AZ placement and, combined with its route
table, whether they can be reached from the internet.

## Route Tables

The rules that decide where traffic from a subnet actually goes — each entry says
"traffic to this CIDR goes to this target" (a gateway, a peering connection, a NAT
gateway...). A subnet is "public" or "private" purely because of what's in **its** route
table, nothing else:
- Route table has `0.0.0.0/0 → Internet Gateway` → that subnet is **public**.
- No such route (traffic to the internet goes through a NAT Gateway instead, if at all)
  → that subnet is **private**.

## Internet Gateway

A horizontally-scaled, VPC-attached component that allows **two-way** communication
between the VPC and the public internet. Exactly one per VPC, and it only does anything
for subnets whose route table actually points `0.0.0.0/0` at it.

## NAT Gateway

Lets instances in a **private subnet** initiate outbound connections to the internet
(e.g., to download OS updates) **without** being reachable from the internet inbound —
the "N" stands for Network Address Translation: outbound packets get rewritten to the NAT
Gateway's own public IP, so nothing outside ever sees the private instance's address
directly, and nothing outside can open a new connection back in.

## Security Groups (recap in VPC context)

Covered in depth in [`../02-ec2`](../02-ec2) — stateful, attached directly to
instances/ENIs, allow-rules only.

## Network ACLs

A **stateless, subnet-level** firewall — unlike Security Groups, NACLs support explicit
`Deny` rules, are evaluated in numbered rule order (lowest number wins), and being
stateless means a response to allowed inbound traffic must be explicitly allowed outbound
too (or it's blocked). NACLs are a second, coarser layer of defense on top of Security
Groups — most setups lean on Security Groups for day-to-day rules and only reach for
NACLs when something needs an explicit `Deny` (e.g., blocking one specific malicious IP
range at the subnet level).

## Public vs Private Subnet

The whole point of carving a VPC into both:
- **Public subnet** — load balancers, bastion hosts: things that genuinely need to be
  reachable from the internet.
- **Private subnet** — app servers, databases: everything else, reachable only from
  inside the VPC (or through whatever's in the public subnet), with outbound-only internet
  access via a NAT Gateway if even that's needed.

This is the standard shape of nearly every production AWS network: a thin public layer in
front of a much larger private layer that's never directly internet-reachable.
