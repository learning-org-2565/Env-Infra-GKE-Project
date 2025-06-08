# Module 3: GKE Cluster Destruction - Real Breaking Scenarios

## Scenario 1: Node Pool Capacity Disaster

### Step 1: Break It
```hcl
# In your GKE module - Set impossible constraints
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.gke_cluster_name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  node_count = 1

  autoscaling {
    min_node_count = 10   # Min > current nodes
    max_node_count = 5    # Max < min - IMPOSSIBLE!
  }

  node_config {
    machine_type = "n1-ultramem-160"  # Expensive/unavailable
    disk_size_gb = 50000              # Huge disk
  }
}

terraform apply
```

### Step 2: What Breaks
```
Error: Error updating NodePool: googleapi: Error 400: 
Invalid value for field 'resource.autoscaling.minNodeCount': '10'. 
The minimum node count (10) cannot be greater than the maximum node count (5).

Error: Insufficient quota for resource 'SSD_TOTAL_GB'
Error: Machine type 'n1-ultramem-160' is not available in zone
```

### Step 3: Fix It
```hcl
# Fix node pool configuration
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.gke_cluster_name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  node_count = 1

  autoscaling {
    min_node_count = 1    # Logical minimum
    max_node_count = 3    # Reasonable maximum
  }

  node_config {
    machine_type = "e2-medium"  # Available, cost-effective
    disk_size_gb = 100          # Reasonable disk size
  }
}
```

### Step 4: What You Learned
- Min node count must be ≤ max node count
- Check machine type availability in your zones
- Monitor your quotas before scaling

---

## Scenario 2: Service Account Permission Explosion

### Step 1: Break It
```bash
# Remove critical permissions from your GKE service account
PROJECT_ID="turnkey-guild-441104-f3"
SA_EMAIL="githubactions-sa@turnkey-guild-441104-f3.iam.gserviceaccount.com"

# Remove critical permissions
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.admin"

gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/compute.admin"

# Try to scale your deployment
kubectl scale deployment your-app --replicas=10
```

### Step 2: What Breaks
```bash
# Check node status
kubectl get nodes
# Some nodes will show NotReady

# Check events
kubectl get events | grep -i error
# You'll see permission-related errors
```

### Step 3: Fix It
```bash
# Restore permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/compute.admin"

# Wait for permissions to propagate
sleep 60

# Verify nodes recover
kubectl get nodes
```

### Step 4: What You Learned
- GKE service accounts need specific permissions
- Permission changes take time to propagate
- Monitor node status after permission changes

---

## Scenario 3: Network Policy Chaos

### Step 1: Break It
```yaml
# Apply strict network policies that block everything
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}  # Apply to all pods
  policyTypes:
  - Ingress
  - Egress
  # No ingress or egress rules = DENY ALL
EOF
```

### Step 2: What Breaks
```bash
# Test pod-to-pod connectivity
kubectl run test1 --image=alpine:latest --restart=Never -- sleep 3600
kubectl run test2 --image=alpine:latest --restart=Never -- sleep 3600

# Get pod IPs
kubectl get pods -o wide

# Try to ping between pods
kubectl exec -it test1 -- ping [test2-ip]
# This will fail: ping timeout

# Try external connectivity
kubectl exec -it test1 -- ping 8.8.8.8
# This will also fail
```

### Step 3: Fix It
```bash
# Remove the restrictive policy
kubectl delete networkpolicy deny-all

# Test connectivity again
kubectl exec -it test1 -- ping [test2-ip]
# Should work now

# Clean up test pods
kubectl delete pod test1 test2
```

### Step 4: What You Learned
- Network policies are deny-by-default when applied
- Empty network policy blocks ALL traffic
- Always test connectivity after applying network policies

---

## Scenario 4: Resource Quota Explosion

### Step 1: Break It
```yaml
# Apply restrictive resource quotas
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: restrictive-quota
spec:
  hard:
    requests.cpu: "0.1"      # Extremely low CPU
    requests.memory: "64Mi"  # Very low memory
    pods: "2"               # Only 2 pods total
    services: "1"           # Only 1 service
EOF
```

### Step 2: What Breaks
```bash
# Try to deploy something
kubectl create deployment nginx --image=nginx:latest --replicas=3

# Check deployment status
kubectl get deployments
# Should show 0/3 ready

# Check events
kubectl get events | grep quota
# You'll see quota exceeded errors
```

### Step 3: Fix It
```bash
# Remove restrictive quota
kubectl delete resourcequota restrictive-quota

# Check deployment recovers
kubectl get deployments
# Should show 3/3 ready now

# Clean up
kubectl delete deployment nginx
```

### Step 4: What You Learned
- Resource quotas limit what can be deployed
- Quotas apply to the entire namespace
- Always plan quotas based on actual usage

---

## Scenario 5: Image Pull Disaster

### Step 1: Break It
```yaml
# Deploy app with inaccessible image
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: app
        image: private-registry.example.com/app:latest  # Private registry without auth
        imagePullPolicy: Always
EOF
```

### Step 2: What Breaks
```bash
# Check pod status
kubectl get pods
# Should show ImagePullBackOff

# Check detailed error
kubectl describe pod [broken-app-pod-name]
# Look for "Failed to pull image" errors
```

### Step 3: Fix It
```bash
# Use a public image instead
kubectl set image deployment/broken-app app=nginx:latest

# Check pods recover
kubectl get pods
# Should show Running status

# Clean up
kubectl delete deployment broken-app
```

### Step 4: What You Learned
- ImagePullBackOff means authentication or image not found
- Always verify image accessibility
- Use image pull secrets for private registries

---

## Scenario 6: Load Balancer Service Failure

### Step 1: Break It
```yaml
# Create service with wrong configuration
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: broken-loadbalancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 9999  # Port that doesn't exist on pods
    protocol: UDP     # Wrong protocol
  selector:
    app: non-existent-app  # No pods match this selector
EOF
```

### Step 2: What Breaks
```bash
# Check service status
kubectl get svc broken-loadbalancer
# External IP will show <pending>

# Check endpoints
kubectl get endpoints broken-loadbalancer
# Should show no endpoints

# Check service details
kubectl describe svc broken-loadbalancer
# Look for warning events
```

### Step 3: Fix It
```bash
# Delete broken service
kubectl delete svc broken-loadbalancer

# Create working service for nginx
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check it works
kubectl get svc nginx
# Should eventually show external IP

# Clean up
kubectl delete deployment nginx
kubectl delete svc nginx
```

### Step 4: What You Learned
- Services need matching pods (selector)
- Port configuration must match pod ports
- LoadBalancer type requires cloud provider support

---

## Scenario 7: Persistent Volume Chaos

### Step 1: Break It
```yaml
# Create PVC with impossible requirements
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: impossible-pvc
spec:
  accessModes:
    - ReadWriteMany  # Not supported by standard GCE disks
  resources:
    requests:
      storage: 100Ti  # Huge size
  storageClassName: "non-existent-storage-class"
EOF
```

### Step 2: What Breaks
```bash
# Check PVC status
kubectl get pvc impossible-pvc
# Should show Pending

# Check detailed error
kubectl describe pvc impossible-pvc
# Look for storage class not found errors
```

### Step 3: Fix It
```bash
# Delete broken PVC
kubectl delete pvc impossible-pvc

# Create working PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: working-pvc
spec:
  accessModes:
    - ReadWriteOnce  # Supported by GCE disks
  resources:
    requests:
      storage: 10Gi  # Reasonable size
  storageClassName: "standard"  # Default GKE storage class
EOF

# Check it works
kubectl get pvc working-pvc
# Should show Bound

# Clean up
kubectl delete pvc working-pvc
```

### Step 4: What You Learned
- Check available storage classes: `kubectl get storageclass`
- ReadWriteMany not supported on GCE persistent disks
- Always verify storage size is reasonable

---

## Your Assignment

1. **Complete Modules 1 & 2 first**
2. **Have a working GKE cluster**
3. **Try each scenario in order**
4. **Actually break things and observe errors**
5. **Practice troubleshooting with kubectl**

## Essential kubectl Commands for Troubleshooting

```bash
# Check cluster and nodes
kubectl get nodes
kubectl describe node [node-name]

# Check pods and deployments
kubectl get pods --all-namespaces
kubectl describe pod [pod-name]
kubectl logs [pod-name]

# Check services and networking
kubectl get svc
kubectl get endpoints
kubectl describe svc [service-name]

# Check resources and quotas
kubectl get quota
kubectl top nodes
kubectl top pods

# Check events for errors
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events | grep -i error

# Clean up resources
kubectl delete pod [pod-name]
kubectl delete deployment [deployment-name]
kubectl delete svc [service-name]
```

## Next Steps

After completing these GKE scenarios, you'll understand:
- Node pool management and troubleshooting
- Service account permissions for GKE
- Network policies and pod connectivity
- Resource quotas and limits
- Image pulling and registry authentication
- Service configuration and load balancers
- Persistent volume management

Ready for advanced module development next!