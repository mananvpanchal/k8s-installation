## Kubernetes Cluster on Fedora 41 VirtualBox with Active Firewall (CRI-O + Flannel)

This guide describes how to create a three-node Kubernetes cluster consisting of:

- **Control Plane**
  - `controlnode` - `192.168.1.100`
- **Compute Plane**
  - `computenode1` - `192.168.1.201`
  - `computenode2` - `192.168.1.202`

### Assumptions

The scripts are written with the following assumptions

- Gateway: `192.168.1.1`
- DNS Server: `192.168.1.1`
- All VMs are connected using Bridge Adapter

And with the hard coded values

- Pod CIDR: `10.244.0.0/16`
- Service CIDR: `10.96.0.0/12`

The following files are provided:

- `k8s-base.sh`
- `k8s-control.sh`
- `k8s-compute.sh`

Check SSH connectivity from host to VMs, and VM to VM before proceeding.

---

## Step 1 - Configure All Nodes

Run base setup script on **every node**.

Syntax:

```bash
sudo sh k8s-base.sh <hostname> <ip-address>
```

Example:

```bash
sudo sh k8s-base.sh controlnode 192.168.1.100

sudo sh k8s-base.sh computenode1 192.168.1.201

sudo sh k8s-base.sh computenode2 192.168.1.202
```

---

## Step 2 - Initialize the Control Plane

Login to the control node and execute:

```bash
sudo sh k8s-control.sh
```

---

## Step 3 - Save the kubeadm output

The control script prints the output from `kubeadm init`.

**Save this output** in a file.

You will need it later because it contains:

- The `kubeadm join` command

---

## Step 4 - Configure kubectl

Create the kubeconfig directory:

```bash
mkdir -p $HOME/.kube
```

Copy the administrator configuration:

```bash
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
```

Grant ownership to the current user:

```bash
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## Step 5 - Verify the Control Plane

Verify that the control node is available:

```bash
kubectl get nodes
```

Expected output:

```text
NAME          STATUS
controlnode   Ready
```

---

## Step 6 - Install the Flannel CNI Plugin

Install Flannel:

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/download/v0.28.8/kube-flannel.yml
```

Wait until all system pods become healthy:

```bash
kubectl get pods -A
```

---

## Step 7 - Prepare Compute Plane

Run the compute plane node setup script on **each compute plane node**.

```bash
sudo sh k8s-compute.sh
```

---

## Step 8 - Join Compute Plane

From the output saved in **Step 3**, copy the generated `kubeadm join` command.

Run the command on **each compute plane node**.

Example:

```bash
sudo kubeadm join <control-plane-ip>:6443 \
    --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```
Or you can generate new join command running

```
sudo kubeadm token create --print-join-command
```
on control node.

---

## Step 9 - Verify Cluster Nodes

On the control node:

```bash
kubectl get nodes
```

Expected output:

```text
NAME            STATUS
controlnode     Ready
computenode1    Ready
computenode2    Ready
```
**Restart cluster** (Shutdown computenodes first then controlnode, and start in reverse order)

---

## Step 10 - Verify the Cluster

Run the verification commands contained in [k8s-verify.md](k8s-verify.md)

The verification covers:

- Node readiness
- System pods
- Pod-to-Pod communication
- Pod-to-Service communication
- DNS resolution
- Internet connectivity
- Cross-node networking

---

## Cluster Topology

| Node | Role | IP Address |
|------|------|------------|
| controlnode | Control Plane | 192.168.1.100 |
| computenode1 | Compute plane | 192.168.1.201 |
| computenode2 | Compute plane | 192.168.1.202 |

---

## Network Configuration

| Component | Value |
|-----------|-------|
| Gateway | 192.168.1.1 |
| DNS | 192.168.1.1 |
| Pod CIDR | 10.244.0.0/16 |
| Service CIDR | 10.96.0.0/12 |

## Versions

| Component | Value |
|-----------|-------|
| CNI | Flannel v0.28.8 |
| Container Runtime | CRI-O |
| Kubernetes Version | v1.34.x |
