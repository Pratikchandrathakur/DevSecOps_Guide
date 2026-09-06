# VPC, Subnet, and Routing Guide

## Build Order
1. Create VPC `10.0.0.0/16`
2. Create 6 subnets across 2 AZs
3. Attach IGW
4. Create NAT GW in Public Subnet 1 with EIP
5. Create/associate route tables:
   - Public RT: `0.0.0.0/0 -> IGW`
   - Private App RT: `0.0.0.0/0 -> NAT`
   - DB RT: no internet route

## Validation
- Public subnet instances have internet if needed
- Private app instances have outbound internet only
- DB instances unreachable from internet
