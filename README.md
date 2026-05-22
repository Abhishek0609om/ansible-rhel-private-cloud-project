# Automated Enterprise RHEL 9 Private Cloud Cluster

An automated, high-availability multi-node enterprise infrastructure architecture built on AWS using **Terraform** for Infrastructure as Code (IaC) and **Ansible** for Configuration Management.

## 📐 Architecture Topology

- **1 x Control Node** (Ansible Engine Management Station)
- **1 x Load Balancer** (HAProxy Layer-7 Reverse Proxy)
- **2 x Web Servers** (Apache HTTPD Application Cluster)
- **1 x Storage Node** (Centralised Network File System - NFS Server)
- **1 x Database Node** (MariaDB Relational Database Management System)

## 🚀 Deployment Workflow

This project follows a professional GitOps local-to-cloud delivery model:
1. **Local Authoring**: Infrastructure topology and automation playbooks are coded in **VS Code**.
2. **Version Control**: Committed locally and pushed securely to **GitHub** (with absolute binaries excluded via strict `.gitignore` filters).
3. **Infrastructure Provisioning**: Run `terraform apply` locally to stand up 6 bare-metal Red Hat Enterprise Linux 9 instances on AWS.
4. **Configuration Execution**: The repository is cloned onto the AWS `control-node` via SSH, executing a master unified playbook (`site.yml`) to provision the entire cluster over the internal VPC network.

## 🛠️ Technology Stack & Automation Configurations

### 1. Infrastructure (Terraform)
- Custom AWS VPC (`172.31.0.0/16`) with public subnet routing mapping an Internet Gateway.
- Security group policies configurations with tight egress access rules and custom self-referencing cross-cluster communication rings.

### 2. Base Configuration (`site.yml` -> `hosts: all:!control`)
- Clear DNF metadata caches to avoid transaction payload corruptions.
- Cluster-wide installations of administration core tools (`vim`, `git`, `curl`, `wget`).
- Standardised activation of native Linux `firewalld` system daemons across all endpoints.

### 3. High Availability Web Tier (`hosts: lb` & `hosts: webservers`)
- Dual-node Apache `httpd` deployments using custom virtual endpoints.
- High-performance HAProxy implementation running a `roundrobin` load balancing algorithm across target private IPs (`172.31.1.155`, `172.31.1.88`).

### 4. Distributed Storage Tier (`hosts: storage`)
- Dedicated NFS Server exporting standard file systems (`/var/nfsshare/html`) mapped to the local subnet CIDR.
- Automated client mount hooks (`ansible.posix.mount`) mapped inside client `/etc/fstab` modules for cross-reboot persistence.

### 5. Backend Database Tier (`hosts: db`)
- Distributed standalone MariaDB engine server instance orchestration.
- System security adjustments allowing local subnet traffic matching port `3306` inside firewalld zones.

## 📊 Verification & Health Audits

Execute these commands inside the `control-node` console path to audit cluster status parameters:

```bash
# Verify global target ping-pong metrics
ansible all -m ping

# Simulate cluster configuration status dry-runs
ansible-playbook site.yml --check

# Execute production cluster baseline transformations
ansible-playbook site.yml
```
