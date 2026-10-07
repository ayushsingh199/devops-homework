# AWS S3 — Simple Storage Service

(The service this session's own [Terraform demo](../terraform-s3-demo) actually creates a
real bucket in — against LocalStack — see [`../README.md`](../README.md).)

## What is S3?

Object storage — not a filesystem, not a block device. You store and retrieve whole
**objects** (files, effectively, each up to 5TB) by key, over HTTP(S), with no server to
manage and no fixed capacity limit. It's the backing store for an enormous share of
"serverless" and static-hosting architecture on AWS.

## Buckets

The top-level container for objects — **globally unique** name across *all* AWS accounts
(not just your own), tied to one AWS region at creation (though the name itself has no
region in it). A bucket holds an effectively unlimited number of objects, with no
directory structure underneath it in the traditional sense — see Objects below.

## Objects

A single stored file, identified by a **key** — the full "path-looking" string
(`photos/2026/img001.jpg`). S3 has no real folders: that `/` is just a convention the
console UI renders as folders, but the actual bucket is a flat key-value store. Each
object also carries metadata (content-type, custom headers) and, since all objects are
versioned-or-not per the bucket setting, potentially a version ID.

## Storage Classes

Same durability (11 nines), different retrieval latency/cost tradeoffs:
- **Standard** — frequently accessed, millisecond retrieval, highest cost.
- **Standard-IA / One Zone-IA** — infrequent access, cheaper storage, per-GB retrieval fee.
- **Glacier / Glacier Deep Archive** — archival, minutes-to-hours retrieval time, the
  cheapest storage cost by far.
- **Intelligent-Tiering** — S3 itself monitors access patterns and moves objects between
  tiers automatically.

## Versioning

When enabled on a bucket, **overwriting or deleting an object never actually destroys the
previous copy** — it creates a new version (or a "delete marker") while the old version
stays retrievable. This is the real protection against accidental overwrite/delete; without
it, a bad `PUT` or `DELETE` is simply unrecoverable.

## Lifecycle Policies

Rules that **automatically transition or expire objects** based on age — e.g., move
anything untouched for 30 days to Standard-IA, move it to Glacier at 90 days, delete it
entirely at 365 days. This is how storage cost is managed at scale without anyone manually
auditing old objects.

## Encryption

- **At rest**: SSE-S3 (AWS-managed keys, the simplest default), SSE-KMS (customer-managed
  keys in AWS KMS, with audit logging of key usage), or SSE-C (customer-supplied keys AWS
  never stores).
- **In transit**: enforced via bucket policy requiring `aws:SecureTransport` — refusing
  any plain-HTTP request.

## Bucket Policies

A resource-based IAM policy attached **directly to the bucket** (as opposed to a user/role
policy attached to an identity) — controls who, from where, can do what to this specific
bucket. This is how a bucket is made public (deliberately, via an explicit `Allow` to
`*`), or locked down to only a specific VPC endpoint, independent of whatever IAM identity
policies also apply.

## Common Use Cases

- Static website hosting (HTML/CSS/JS served directly from a bucket, often behind
  CloudFront).
- The durable storage layer behind data lakes, backups, and build artifacts (exactly what
  [Session 16](../../15-cicd-github-actions)'s CI pipeline artifact upload conceptually is
  — GitHub's own artifact storage is S3-backed).
- Hosting Terraform's own remote **state** file (`backend "s3" {}`), so a team shares one
  source of truth for infrastructure state instead of each person holding a local copy.
