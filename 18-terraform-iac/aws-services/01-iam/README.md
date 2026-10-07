# AWS IAM — Identity and Access Management

## What is IAM?

The service that controls **who** (authentication) can do **what** (authorization) to
**which resources** in an AWS account. Every single AWS API call — from the console,
CLI, SDK, or Terraform — is checked against IAM. There is no AWS action that bypasses it,
including actions taken by the account's root user.

## Users

An **IAM User** represents one person or one application with long-term credentials (a
password for console login, and/or access keys for programmatic access). Each user is a
distinct identity with its own permissions — two users don't share credentials, so every
action is individually attributable in CloudTrail logs.

## Groups

A **Group** is just a named collection of Users that a policy can be attached to once,
instead of attaching the same policy to every user individually. Groups cannot be nested
(no groups-within-groups), and a Group itself has no credentials — it's purely an
organizational/permissions convenience.

## Roles

A **Role** is an identity with permissions, like a User, but with no long-term credentials
attached to it at all. Instead, something else **assumes** the role temporarily (an EC2
instance, a Lambda function, a user from another AWS account, or a federated identity like
a Google/SAML login) and receives short-lived credentials that expire automatically. Roles
are how an EC2 instance gets AWS permissions without anyone ever hardcoding an access key
into the instance.

## Policies

A **Policy** is a JSON document that actually defines permissions — a list of statements,
each saying `Effect: Allow/Deny`, on which `Action`s (e.g. `s3:GetObject`), against which
`Resource`s (an ARN, possibly with wildcards), optionally under which `Condition`s (source
IP, MFA present, time of day, etc.). Policies are attached to Users, Groups, or Roles —
the policy document itself grants nothing on its own until attached to an identity.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

## Permissions

A principal's **effective permissions** are the union of every policy attached to it
directly, to any Group it belongs to, and to any Role it has assumed — with one hard rule:
**an explicit `Deny` anywhere always wins**, no matter how many `Allow` statements exist
elsewhere. If nothing explicitly allows an action, it's denied by default (implicit deny).

## Least Privilege

The principle of granting a principal **only the exact permissions it needs to do its job,
nothing more** — not `s3:*` when `s3:GetObject` on one specific bucket is all that's
actually used. This matters because every unnecessary permission is pure attack surface:
if credentials leak (and they eventually do), the blast radius is capped by what that
identity was actually allowed to do.

## IAM Best Practices

- Never use the **root user** for day-to-day work — lock it away with MFA, use it only for
  the handful of actions that truly require it (closing the account, changing the support
  plan).
- Prefer **Roles over long-term access keys** wherever possible — an EC2 instance role
  never needs a key that can leak in a git repo.
- Apply **least privilege**, and grow permissions from a minimal baseline rather than
  starting from `*` and trying to narrow down later.
- **Enable MFA** on every human user, especially anyone with administrative permissions.
- **Rotate** any access keys that do have to exist, and delete ones that are unused.
- Use **policy conditions** (source IP ranges, MFA-required, specific VPC endpoints) to
  narrow when a permission can even be exercised.

## Common Use Cases

- Giving a CI/CD pipeline (like a GitHub Actions runner) a Role scoped to exactly the
  deploy actions it needs, with temporary credentials instead of a stored key.
- Letting an EC2 instance read from one specific S3 bucket without any credentials ever
  touching its disk.
- Granting a third-party vendor **cross-account access** to a narrow slice of resources via
  a Role, instead of creating them a User in the account.
- Enforcing that only users who logged in with MFA can delete production resources, via a
  policy `Condition`.
