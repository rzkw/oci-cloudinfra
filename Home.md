<img src="https://docs.oracle.com/en-us/iaas/Content/Bastion/images/bastion-overview-diagram.png" 
        alt="Architecture diagram showing VM in a private subnet accessible only by Bastion service" 
        style="display: block; margin: 0 auto" />

_Architecture diagram showing virtual machine in a private subnet accessible only by Bastion service_ 

---

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
        * Cross-Domain IAM policy
        * Default identity domain
            * Root user for emergency/billing access only (secured with FIDO2 security keys)
            * Root compartment
                * Policies
                * Child compartment for resources
                    * Policies
                    * Instances
                    * Production identity domain for users, groups
                        * Admin user for day to day tasks (also MFA secured)
           

From the top down - the tenancy is the organisational level container, automatically created at sign on. The identity domain acts as a container for managing users and groups. Within the identity domain is a compartment to organise cloud resources, e.g. VM instances, databases. This is important to measure usage and billing, access, and separating resources from one project to another. Resources in one identity domain are isolated from other identity domains. An admin user is allocated to each compartment - to mirror an organisation's departments. 

In day to day use: the tenancy and compartments separate users, groups, and resources according to the identity domain and hierarchy. Restricting access to resources is a way of enforcing the principle of least privilege - granting users the least amount of access required to do their jobs. Limiting access reduces the surface area of attack, in case of accidental/intentional misconfigurations; preventing circumventing of security by data leaks or malicious emails, etc. 

The default identity admin is only to be used for emergency and billing access, as OCI gives this admin privileged access by policy which can't be changed. This guide will show how to create an admin for day to day usage instead, restricting access by IAM policies. 

## How To Guides

### Phase 1: Foundation Setup (As Root User)

These initial steps are performed once by your root administrator (in the Default domain). This establishes the organizational structure and grants operational access to your working identity domain.

#### Step 1: Create Your Operational Compartment

1. Login to OCI Console as your root user
    - Navigate to: https://cloud.oracle.com


2. Open Compartments page
    - Click the ☰ menu (top-left); select Identity & Security → Compartments

3. Click Create Compartment and enter the following:   

---
   

|      **Field**     |                    **Value**                   |                  **Notes**                  |
|:------------------:|:----------------------------------------------:|:-------------------------------------------:|
|        Name        |                     Comp-1                     | This will contain all operational resources |
|     Description    | Operational compartment for dev/test resources |     Helps others understand its purpose     |
| Parent Compartment |                     (root)                     |  Keep default - creates under tenancy root  |

---

4. Click Create Compartment: wait for the compartment to appear in the list (immediate)
    

#### Step 2: Create Your Operational Identity Domain

1. Open Domains page: click ☰ menu → Identity & Security → Domains

2. Click Create Domain, configure:

---

|     Field    |                      Value                     |                   Notes                  |
|:------------:|:----------------------------------------------:|:----------------------------------------:|
| Display name |                   domain-dev                   |        Operational identity domain       |
|  Description | Identity domain for development and operations |             Explains purpose             |
|  Domain type |                      Free                      |    No cost for basic identity services   |
|  Compartment |                     Comp-1                     | Place it in your operational compartment |

---

3. Create admin user: check "Create an administrative user for this domain" and enter user details. Use valid email for login credentials

4. Expand Tags: add one or more tags to domain for billing/admin purposes (i.e. domain-dev)
    
5. Select Next and Create. Status will change from "Creating" to "Active" (2-3 minutes); check your email for the admin user credentials


#### Step 3: Create Cross-Domain Access Policy

Policies control who can do what in OCI. This policy grants your domain-dev administrators full control over Comp-1 while keeping them out of the root compartment. 

1. Open Policies page, click ☰ menu → Identity & Security → Policies

2. Ensure you're at tenancy level: in the Compartment dropdown (left side), select <root> (your tenancy). This is crucial - the policy must be at tenancy root level.

3. Click Create Policy and configure:

| Field       | Value                                                 |
|-------------|-------------------------------------------------------|
| Name        | policy-domain-dev-manages-comp1                       |
| Description | Grant domain-dev administrators full access to Comp-1 |
| Compartment | <root> (tenancy level)                                |

    
4. Add policy statements: toggle 'Show manual editor'. Paste these statements exactly:

```
Allow group 'domain-dev'/'Administrators' to manage all-resources in compartment Comp-1
   Allow group 'domain-dev'/'Administrators' to manage policies in compartment Comp-1
   Allow group 'domain-dev'/'Administrators' to inspect compartments in tenancy
```

5. Create the policy: click Create. 


#### Step 4: Test Cross-Domain Access
Before proceeding, verify your new admin user can access Comp-1 resources.

1. Logout from Default domain: Click your profile icon (top-right), select Sign Out

2. Login as domain-dev admin: Go to https://cloud.oracle.com → Click Sign In → Domain: select domain-dev from dropdown → Username: rizky → Password: use password from email (you'll be prompted to change it)


3. Verify access to Comp-1: click ☰ menu → Identity & Security → Compartments. You should see: Comp-1 listed; can click into Comp-1 details; cannot see hello17 compartment details (expected)

4. Test resource creation: click ☰ menu → Networking → Virtual Cloud Networks. Change compartment filter to Comp-1. Verify you can click Create VCN (don't create yet)

Expected results: can view and access Comp-1; can see "Create" buttons for resources; cannot view resources in hello17 (root compartment)


#### Step 5: Restrict Default Domain Access
This step limits the Default domain administrator to emergency-only access, preventing accidental changes to operational resources. Separation of duties is a security best practice. Your root account should be for emergencies, not daily use.

1. Logout and login as root user.

2. Navigate to Identity & Security → Policies. Ensure compartment is <root> (tenancy level). Click Create Policy: 

| Field       | Value                                                 |
|-------------|-------------------------------------------------------|
| Name        | policy-domain-dev-manages-comp1                       |
| Description | Grant domain-dev administrators full access to Comp-1 |
| Compartment | <root> (tenancy level)                                |


3. Add policy statement: toggle 'Show manual editor' and paste:

```
Allow group 'Default'/'Administrators' to manage all-resources in compartment hello17
```

#### End of Phase 1 checklist:

- [ ] Operational compartment (Comp-1)
- [ ] Operational identity domain (domain-dev) with admin user (rizky)
- [ ] Cross-domain policies granting proper access
- [ ] Tested and verified access works
- [ ] Restricted root access for security

---

### Phase 2: Network & Infrastructure Setup (Operational Admin)

Now we build the actual infrastructure: network, compute, and secure access. These steps are performed by the domain-dev administrator.

*Important:* Make sure you're logged in as admin (domain-dev domain) before proceeding.

#### Step 6: Create Your Virtual Cloud Network (VCN)
A VCN is your private network in the cloud. It's like setting up your own router and network at home, but in Oracle's data center.

1. Navigate to VCN page: click ☰ menu → Networking → Virtual Cloud Networks
Important: Change compartment to Comp-1 (left sidebar)

2. Click Create VCN. Configure VCN basics:

- Name: vcn-1
- Create in Compartment: Comp-1
- IPv4 CIDR Block: 10.0.0.0/16
- Check "Use DNS Hostnames in this VCN". 
- Tags
    - ResourceType: Network
    - CostCenter: Infrastructure
    - SecurityZone: Production
    - Criticality: High 

 Click Create VCN. 


#### Step 7: Create Subnets
Subnets divide your VCN into smaller segments. We'll create two: one public (for gateways) and one private (for your servers).

1. To create public subnet: Navigate to your VCN: click on vcn-1 from the VCN list; click Subnets tab, click Create Subnet. 

- Name: public-subnet-1
- Create in Compartment: Comp-1
- Subnet Type: Regional Recommended - spans all availability zones
- IPv4 CIDR Block: 10.0.0.0/24
- Subnet Access: Public Subnet
- Check "Use DNS Hostnames in this Subnet"
- Select Default Security List for vcn-1
- Tags:
    - SubnetType: Public
    - CostCenter: Infrastructure
    - AllowPublicIP: True
    - Purpose: Gateways

Click Create Subnet.

2. To create private subnet: click Create Subnet again. 

- Name: private-subnet-1
- Create in Compartment: Comp-1
- Subnet Type: Regional
- IPv4 CIDR Block: 10.0.1.0/24
- Subnet Access: Private Subnet
- Check "Use DNS Hostnames in this Subnet"
- Select Default Security List for vcn-1
- Tags:
    - SubnetType: Public
    - CostCenter: Infrastructure
    - AllowPublicIP: False
    - Purpose: ComputeInstances

Click Create Subnet.


3. Verify both subnets were created: navigate to VCN1 → Subnets. You should see:

- public-subnet-1 (10.0.0.0/24)
- private-subnet-1 (10.0.1.0/24)


#### Step 8: Update Private Subnet Security List
Security lists act as firewalls for your subnets. We need to allow SSH traffic (port 22) from the Bastion service.

1. From your VCN-1 page, click Security tab → click Default Security List for vcn-1 → Security rules tab → Ingress Rules: Add ingress rules 

- Source Type: CIDR
- Source CIDR: 
- IP Protocol: TCP
- Source Port Range: (leave empty)
- Destination Port Range: 22 
- Description: Allow SSH from Bastion

Click Add Ingress Rules.

#### Step 9: Create Compute Instance

Now we create the actual server (VM) in the private subnet. We'll use Always Free tier resources to minimize costs.

1. Click ☰ menu → Compute → Instances → click Create instance 

Configure: 
FieldValueNamevm-1CompartmentComp-1TagsResourceType: ComputeCostCenter: OperationsEnvironment: ProductionOwner: domain-devBackupPolicy: DailyCriticality: High
Tags Required - enables:

Cost allocation and chargeback
Automated backup scheduling
Security compliance tracking
Disaster recovery prioritization

2. Configure placement: Availability Domain: leave default; Fault Domain: let Oracle choose (default)

3. Image: Change Image → click Ubuntu, scroll down to pick 22.04 or latest → click Select Image

4. Shape: Change shape → Select Virtual Machine → Shape series: Select Ampere → Select VM.Standard.A1.Flex then small arrow next to VM name → Number of OCPUs: 4 → Amount of memory (GB): 24 → click Select Shape.

5. Security: Enable Shielded instance

6. Networking: 

- Primary VNIC: VNIC-1 → Primary network: Select existing virtual cloud network → Virtual cloud network compartment: Comp-1 → Virtual cloud network: vcn-1
Subnet: Select existing subnet → Subnet compartment: Comp-1 → Subnet: private-subnet-1 (regional) 

- Private IPv4 address assignment: Automatically assign private IPv4 address 

- Add SSH keys: Generate a key pair for me (recommended for beginners) → click Download private Key and Download public key. IMPORTANT: Store these files securely - you can't download them again!

- Storage: In Boot volume, click Specify a custom boot volume size and performance setting → Boot volume size (GB): 200 → check Use in-transit encryption. Leave other options default

8. Click Next to Review your instance's Basic information and click Create.


#### Step 10 : Connect Private Subnet to Internet (NAT Gateway via Quick Actions)
Now we'll use Oracle's Quick Actions feature to automatically set up internet access for your private subnet. This creates the NAT Gateway, route table, and necessary configurations in one step.


1. Click on vm-1 from the Instances list, ensure vm-1 status is "Running" → click Networking tab → scroll down to Quick actions → click Connect under "Connect private subnet to internet" 

2. Review automatic configuration. Oracle automatically creates:

- NAT Gateway (NAT gateway-VCN1)
- Network security group
- Route table rule: 0.0.0.0/0 → NAT Gateway

Click Create to confirm. 

3. To verify NAT Gateway was created, navigate to: Networking → Virtual Cloud Networks → vcn-1 → click Gateways tab → You should see: nat-gateway-1 with status "Available"

4. To verify route table updated - navigate to Routing, find the route table associated with private-subnet-1. It should show rule with Destination 0.0.0.0/0 targeting nat-gateway-1

5. Add tags to NAT Gateway - click Tags → Add 

Add:
- GatewayType: NAT
- CostCenter: Infrastructure
- Purpose: OutboundInternet
- Criticality: Medium

#### Step 12: Create Bastion Service, enable plugin and create session 
The Bastion service provides secure, audited SSH access to your private instances without exposing them to the public internet.

1. Find your public IP address: open new browser tab and go to https://www.whatismyip.com. Note your IP address (e.g., 203.45.67.89). This is your computer's public internet IP - not your local network IP (192.168.x.x)

2. In OCI: Click ☰ menu → Identity & Security → Bastion → Create bastion.

Configure:

- Bastion Name: bastion-1
- Target virtual cloud network compartment: Comp-1
- Target virtual cloud network: VCN1
- Target subnet compartment: Comp-1
- Target subnet: private-subnet-1
- CIDR block allowlist: YOUR.PUBLIC.IP/32 (e.g., 203.45.67.89/32) from step 1  (allowing only your computer's public IP address - most secure)
- Advanced options: Maximum session time-to-live (TTL): 60 minutes
- Tags: 
    - ResourceType: SecurityService
    - CostCenter: Security
    - Purpose: SecureAccess
    - Criticality: High
    - AuditRequired: TrueRequired - enables security auditing, compliance tracking, and access monitoring

Click Create bastion. 

3. Navigate to your VM - click ☰ menu → Compute → Instances → click vm-private-01. Scroll to Oracle Cloud Agent in Management tab → find Bastion in the plugin list and toggle switch to Enabled. Status will change from "Stopped" to "Running". Wait 5-10 minutes for full initialization

4. Navigate back to Bastion in Identity & Security, click bastion-prod and click Sessions tab → Create Session.

- Session type: Managed SSH session
- Username: ubuntu
- Compute instance compartment: Comp-1
- Compute instance: VM-1
- Choose SSH key file: select the public key you saved earlier from step 9. 

Click Create session, wait for status "Active" (30-60 seconds). 

Click ... and Copy SSH command. Copy the SSH command into a text editor and paste in the path for your private key in the `<privateKey>` part. 

```
ssh -i /Users/path/to/private.key -o ProxyCommand="ssh -i /Users/path/to/private.key -W %h:%p -p 22 ocid1.example@host.bastion.eample.oci.oraclecloud.com" -p 22 ubuntu@ip.address
```

4. Open Terminal and paste/enter your entire SSH command. Type 'yes' at the `Are you sure you want to continue connecting (yes/no/[fingerprint])?` prompt. 

5. Test connectivity:

```
# Test HTTP connectivity
curl -I https://www.google.com

# Update packages
sudo apt update && sudo apt upgrade
```

---

## Expansion

- Adding more team members 

## Troubleshooting

- Cannot view resources after cross-domain policy has been created
If you see errors: The policy may not have taken effect yet. Wait 1-2 minutes and refresh the page.

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
* [Use a bastion to access your VM - Ubuntu on Oracle](https://documentation.ubuntu.com/oracle/oracle-how-to/use-bastion-to-access-VM/)

## 📝 License & Disclaimer

This documentation is provided for educational and reference purposes. 

Oracle Cloud Infrastructure®, Oracle®, and related trademarks are property of Oracle Corporation and/or its affiliates. This project is not affiliated with or endorsed by Oracle Corporation.

**Use at your own risk.** Always test in non-production environments first and follow your organization's security policies.

---

## 🏷️ Tags

`oracle-cloud` `oci` `infrastructure` `bastion` `security` `iam` `networking` `cloud-architecture` `labs`

---

**Maintained by:** [@rzkw](https://github.com/rzkw) | Built with ☕ at home
