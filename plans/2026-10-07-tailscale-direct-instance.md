# Tailscale-Ready OCI Instance Plan

Date: 2026-10-07
Status: Approved (PR #110)
Repos: `rzkw/oci-cloudinfra`, `rzkw/ansible`

## Goal and design

Provision the Ubuntu 24 instance unattended with CIS Level 1 Server hardening, base/dev-box setup, Tailscale, and key-only SSH for `ubuntu`, `rizky`, and `agent-walkllc`. Attach the existing reserved public IP and keep default internet routing through the IGW. Retain TCP/22 from the VCN dev subnet for the managed Bastion fallback; do not expose SSH publicly or remove this fallback in this change. Tailscale connectivity checks run after deployment.

Cloud-init will run `ansible-pull` without Vault or a TTY. Remove active Vault dependencies and optional vault-backed config writes; preserve historical plans and mark the pending vault-password plan superseded. Pin `ansible-lockdown/UBUNTU24-CIS` at 1.7.0 and apply only the Level 1 Server remediation tags. Disable SSH password authentication; use the Terraform SSH key for `ubuntu`, `dev-box-backup` for `rizky`, and a non-secret agent public-key input for `agent-walkllc`. Never copy the agent private key. Keep the agent unprivileged; use Bastion `ubuntu` for privileged checks.

## Changes and checks

- OCI: attach `oci_core_public_ip.pubip` to the instance’s primary private IP and set `assign_public_ip = false`; replace the broken bootstrap URL with cloud-init package setup plus `ansible-pull`. Preserve the IGW route, stateless UDP/41641, and TCP/22 from the dev subnet.
- Ansible: make `server.yml` noninteractive and Vault-independent; create/configure the three SSH users before CIS hardening; fix Tailscale metadata access to authenticated OCI `/opc/v2`; allow host-firewall SSH only over `tailscale0` and the dev subnet, plus UDP/41641. Keep the Tailscale auth key out of logs.
- Static checks: Terraform fmt/validate for all four OCI modules; Ansible lint and syntax-check; verify no prompt/pause/ask-password step is reachable from cloud-init.
- Post-deploy: inspect cloud-init/Ansible logs via Bastion; run the CIS audit after any required reboot; verify packages, timezone, apt automation, SSH keys and key-only login; test Bastion `ubuntu`; then run repeated `tailscale ping --until-direct home` checks and confirm `tailscale status` shows `direct`. Confirm public TCP/22 is unreachable. Keep the Bastion rule regardless of a single successful direct check.

## Cost and budget

Incremental OCI estimate: **AUD $0/month**; no billable resources are added, and the already-created reserved IP replaces the instance’s current ephemeral public-IP assignment. Live tenancy budget: **AUD $1.00/month** (`Dollar-Budget`, monthly), read with the OCI CLI. No apply until the approved plan is merged and the budget check still passes.

## References

- Tailscale public-IP/UDP guidance: https://tailscale.com/blog/nat-traversal-improvements-pt-2-cloud-environments#give-the-instance-a-public-ip-and-open-the-firewall
- OCI reserved-IP assignment: https://docs.oracle.com/en/learn/oci-attach-reserved-ip/index.html (excluding secondary-VNIC/cloud-init steps)
- OCI Terraform public IP: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip
- Tailscale connection verification: https://tailscale.com/docs/reference/connection-types
- Ansible pull: https://docs.ansible.com/ansible/latest/cli/ansible-pull.html
- Ubuntu 24 CIS release 1.7.0 and Level 1 Server tags: https://github.com/ansible-lockdown/UBUNTU24-CIS/tree/1.7.0
