Welcome to the oci-cloudinfra wiki!

## Project Overview
A secure, production-ready Oracle Cloud Infrastructure setup featuring a private Virtual Cloud Network (VCN) with Bastion-based access control and cross-domain IAM policies.


## Quick Navigation

* [Getting Started](#getting-started)
* [Architecture Overview](#architecture-overview)
* [Security & IAM](#security--iam)
* [How To Guides](#how-to-guides)
* [Troubleshooting](#troubleshooting)
* [Business Impact](#business-impact)
* [References](#references)

Project Status: ⚠️ Building \
Last Updated: November 2025


## Getting Started

This project demos a small but secure, isolated cloud infrastructure on Oracle Cloud using industry standard best practices: network segmentation and identity/access management (IAM). Practical use cases for this setup include a test environment for a dev agency, students learning IT/Computer Science and e-commerce business inventory/analytics.

### What You'll Learn

* Building a Virtual Cloud Network (VCN) with public & private subnets
* Implementing Bastion service for secure SSH access
* Configuring cross-domain IAM policies
* Setting up NAT Gateway for outbound connectivity
* Enabling security controls and audit logging

### Prerequisites

* Oracle Cloud Infrastructure account (Free Tier or Pay As You Go)
* An understanding of networking fundamentals (CIDR blocks, subnets, routing)
* Some familiarity with the Linux command line

## Architecture Overview

* Region
    - Availability domain
        - VCN (10.0.0.0/16)
           - Public subnet (10.0.0.0/24)
                - No resources yet but available for expansion
            - Private subnet (10.0.1.0/24)
                - Virtual Machine (VM) instance
            - NAT gateway
            - Network security group
            - Route table    
    - Bastion service

This setup plans a virtual cloud network (VCN) for future expansion, allowing the creation of more subnets in future in case the business requires it (for instance: migrating workloads from on-premises).

This setup also maintains network separation for production, test and dev environments. Access to VMs inside the private subnet is restricted using the Bastion service, limited by time, maintaining a strong security posture. 

## Security & IAM

* Region
    * Tenancy
        * Default identity domain
            * Root user for emergency/billing access only (secured with FIDO2 security keys)
           * Root compartment
                * Policies
       * Production identity domain for users, groups
           * Admin user for day to day tasks (also MFA secured)
           * Compartment for resources
                * Policies
                * Instances

From the top down - the tenancy is the organisational level container, automatically created at sign on. The identity domain acts as a container for managing users and groups. Within the identity domain is a compartment to organise cloud resources, e.g. VM instances, databases. This is important to measure usage and billing, acceess, and separating resources from one project to another. Resources in one identity domain are isolated from other identity domains. An admin user is allocated to each compartment - to mirror an organisation's departments. 

In day to day use: the tenancy and compartments separate users, groups, and resources according to the identity domain and hierarchy. Restricting access to resources is a way of enforcing the principle of least privilege - granting users the least amount of access required to do their jobs. Limiting access reduces the surface area of attack, in case of accidental/intentional misconfigurations; preventing circumventing of security by data leaks or malicious emails, etc. 

The default identity admin is only to be used for emergency and billing access, as OCI gives this admin privileged access by policy which can't be changed. This guide will show how to create an admin for day to day usage instead, restricting access by IAM policies. 

## How To Guides
## Troubleshooting
## Business Impact

The VCN, subnetting and IAM structures are scalable, allowing a business to manage users and resources as required while maintaining a high level of security. 

OCI also provides single-sign on (SSO) using third-party applications, for businesses that may prefer using other providers to login to their OCI-based resources. 

IAM access and policies can also minimise accidental (or intentional) misconfigurations, preventing budget blowouts and access to malicious bad actors. This guide uses Always Free resources when possible, but similar configurations on AWS and Azure will likely cost more. 


## References

* [Best Practices for Your Compute Instances](https://docs.oracle.com/en-us/iaas/Content/Compute/References/bestpracticescompute.htm#three)
* [Use Bastion service to access resources in a private subnet](https://docs.oracle.com/en/solutions/use-bastion-service/index.html)
* [OCI Networking Best Practices - Part One - OCI Network Design, VCN, and Subnets](https://www.ateam-oracle.com/post/oci-networking-best-practices-recommendations-and-tips---part-one---general-oci-networking)
* [Best Practices for Identity and
Access Management (IAM) in
Oracle Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/Content/Resources/Assets/whitepapers/best-practices-for-iam-on-oci.pdf)

## 📝 License & Disclaimer

This documentation is provided for educational and reference purposes. 

Oracle Cloud Infrastructure®, Oracle®, and related trademarks are property of Oracle Corporation and/or its affiliates. This project is not affiliated with or endorsed by Oracle Corporation.

**Use at your own risk.** Always test in non-production environments first and follow your organization's security policies.

---

## 🏷️ Tags

`oracle-cloud` `oci` `infrastructure` `bastion` `security` `iam` `networking` `cloud-architecture` `labs`

---

**Maintained by:** [@rzkw](https://github.com/rzkw) | Built with ☕ at home
