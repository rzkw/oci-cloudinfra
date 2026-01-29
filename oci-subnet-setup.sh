#!/bin/bash
# Script to deploy a VCN, gateway, NAT, route table, sec lists, 2 public and private subnets in existing VCN on OCI. Written with help of Gemini and official OCI documentation
# To run the script: enter "source .env" in terminal, then ./oci-subnet-setup.sh



# Variables
comp_id="${OCI_COMP_ID}"
vcn_cidr="10.0.0.0/16"

# Create VCN

echo "Creating VCN..."

vcn_id=$(oci network vcn create --compartment-id $comp_id --display-name "VCN-1" --dns-label vcn1 --cidr-blocks '["10.0.0.0/16"]' --query "data.id" --raw-output)


# Create gateways

echo "Creating gateways..."

gateway_id=$(oci network internet-gateway create --compartment-id $comp_id --vcn-id $vcn_id --is-enabled true --display-name "gateway1" --query "data.id" --raw-output)
nat_id=$(oci network nat-gateway create --compartment-id $comp_id --vcn-id $vcn_id --display-name "NAT1" --query "data.id" --raw-output)

# Create route tables

echo "Setting up routing..."

# Public route table (to Internet Gateway)

rt_pub_id=$(oci network route-table create --compartment-id $comp_id --vcn-id $vcn_id --display-name "public-route-table" --route-rules '[{"cidrBlock": "0.0.0.0/0", "networkEntityId": "'$gateway_id'"}]' --query "data.id" --raw-output)

# Private route table (to NAT gateway)

rt_priv_id=$(oci network route-table create --compartment-id $comp_id --vcn-id $vcn_id --display-name "private-route-table" --route-rules '[{"cidrBlock": "0.0.0.0/0", "networkEntityId": "'$nat_id'"}]' --query "data.id" --raw-output)

# Check for public route table

if [[ -z "$rt_pub_id" || ! "$rt_pub_id" =~ ^ocid1 ]]; then
    echo "ERROR public route table id not captured correctly. Check JSON formatting"
    exit 1
fi

# Public security list

echo "Creating security lists..."

sl_pub_id=$(oci network security-list create --compartment-id $comp_id --vcn-id $vcn_id --display-name "public-sl" --egress-security-rules '[{"destination": "0.0.0.0/0", "protocol": "all"}]' --ingress-security-rules '[{"source": "0.0.0.0/0", "protocol": "6", "tcpOptions": {"destinationPortRange":{"min": 22, "max": 22}}}]' --query "data.id" --raw-output)

# Private security list: allow ssh only from within vcn. Remove when Tailscale installed by cloud-iint

sl_priv_id=$(oci network security-list create --compartment-id $comp_id --vcn-id $vcn_id --display-name "private-sl" --egress-security-rules '[{"destination": "0.0.0.0/0", "protocol": "all", "isStateless": false}]' --ingress-security-rules '[{"source": "'$vcn_cidr'", "protocol": "6", "tcpOptions": {"destinationPortRange": {"min": 22, "max": 22}}}]' --query "data.id" --raw-output)

# Create subnets

echo "Creating subnets..."

# 2 public subnets

oci network subnet create --compartment-id $comp_id --vcn-id $vcn_id --cidr-block "10.0.0.0/18" --display-name "public-subnet1" --route-table-id $rt_pub_id --security-list-ids '["'$sl_pub_id'"]'

oci network subnet create --compartment-id $comp_id --vcn-id $vcn_id --cidr-block "10.0.64.0/18" --display-name "public-subnet2" --route-table-id $rt_pub_id --security-list-ids '["'$sl_pub_id'"]'

# 2 private subnets. "Prohibit public ip" parameter = true to create private subnets

oci network subnet create --compartment-id $comp_id --vcn-id $vcn_id --cidr-block "10.0.128.0/18" --display-name "private-subnet1" --prohibit-public-ip-on-vnic true --route-table-id $rt_priv_id --security-list-ids '["'$sl_priv_id'"]'

oci network subnet create --compartment-id $comp_id --vcn-id $vcn_id --cidr-block "10.0.192.0/18" --display-name "private-subnet2" --prohibit-public-ip-on-vnic true --route-table-id $rt_priv_id --security-list-ids '["'$sl_priv_id'"]'

echo "Done!"