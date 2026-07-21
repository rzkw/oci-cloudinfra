# OCI API Scope — agent@walk-llc.com

Account: **hello17** (compartment **Comp-1**, region `ap-melbourne-1`)

## Visible Resources

### Compute

| Resource | Shape | OCPUs | Memory | State | Created |
|----------|-------|-------|--------|-------|---------|
| VM | VM.Standard.A1.Flex | 2 | 12 GB | RUNNING | 2026-07-17 |
| └ VNIC | Private IP `172.16.0.12`, no public IP, hostname `vm` | | | ATTACHED | |
| └ Boot Volume | `ocid1.bootvolume.oc1.ap-melbourne-1...` | | | AVAILABLE | |

### Networking

| Resource | Details |
|----------|---------|
| **My internal VCN** | `172.16.0.0/20`, DNS: `internal.oraclevcn.com` |
| └ Subnet **dev** | `172.16.0.0/24` |
| └ Security List **Internal Security List** | |
| └ Route Table **Dev Route Table** | |
| └ Route Table **service gateway route table** | |
| └ Internet Gateway **Internal Internet Gateway** | AVAILABLE |
| └ Service Gateway **servicegateway20260720114218** | AVAILABLE |

### Storage

| Resource | Details |
|----------|---------|
| **tfstate** bucket | Object storage, namespace `axvczntoncvg`, created 2026-07-06 |

## API Limitations

The API key used (`fingerprint: 6e:42:35:31:66:ce:f8:3f:3e:e5:28:d1:02:c6:05:ce`) has the following access constraints:

- **Read-only** — no write access to any resource or service
- **Compartment-scoped** — only resources in `Comp-1` are visible; root compartment resources (IAM users, groups, policies) return `NotAuthorizedOrNotFound`
- **Region-locked** — cross-region API calls to `ap-singapore-1` and `us-sanjose-1` fail with `NotAuthenticated`
- **No IAM visibility** — cannot list users, groups, or policies; cannot read own user details
- **No platform image visibility** — platform images returned are Oracle's shared image catalog, not compartment-scoped custom images
