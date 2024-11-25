# Considerations about preparing the cluster for Production environments

## Security enhancements

One of the most explored issues with Kubernetes is not about the tool itself, but actually all the images that contians security threats - sometimes patched in updated versions. One of the first steps to improve security is to use a private image registry, such as Azure Container Registry (ACR) to store not all of our custom images, but also as a relay for external images. On this registry we can setup an image scanner tool, such as Microsoft Defender for Cloud for Containers or Snyk. Depending on the severity it might even worth it to block new deployments until the threats are handled.

The network of our cluster is also insecure. Depending on the application we deploy, we might want to expose it externally, and the way we do it can change the security level. For example, in Azure the Kubernetes cluster can remain isolated from the Internet and connect to internal servers via private links. It is also possible to use Azure Frontdoor and APIM to connect applications to the cluster, creating another layer of protection and customization between them.

Another important consideration is the secret management. Secrets are a part of any application, and as we move towards an Infrastructure-as-code method, we cannot store secrets in code. Ideally we would use a secret management  tool that is endorsed in [CNCF Landscape](https://landscape.cncf.io/guide#provisioning--key-management) such as Hashicorp Vault.

Finally, another obvious improvement to our solution is to have a proper user management. Kubernetes itself does not have users, to control access to it we need to make use of external providers. Usually we leverage the Cloud provider solution, in Azure for example we can exclusively use EntraID groups and map them to RBACs to grant permission. It is possible to use independent solutions, such as Okta or StrongDM.

## High availability and fault tolerance

Our Kubernetes cluster is prone to errors and failures. First, it has only one node, and this node is running both the control plane and the user plane workload. If this nodes fails, all applications inside it also fails. To improve this situation, the minimum we should have is two nodes, reducing the chances of a catastrophic failure.

But that is not how usually production clusters are configured, there are many layers of protection. First, we can have at least two nodes dedicated exclusively to the control plane, the "brain" of the cluster. Separating them from the workload means we have more stability when it comes to cluster management.

Secondly, we can have at least two more nodes dedicated to workloads. These nodes can also be bigger - in my personal experience fewer bigger nodes are better, faster and cheaper than many smaller nodes - but having at least two nodes increase resilience of the system. Not only that, instead of having a fixed number of nodes they should be part of a storage pool, meaning we can easily scale it up/down as our workload changes - even automatically.

On top of the cluster node configuration, there are many tools available from cloud providers like Azure, AWS and GCP. One of these features is Availability Zone, meaning on the same region we can have distributed nodes with automatic copies of storage volumes and persistent data. Another interesting solution is the multi-region cluster, where the cluster architecture runs distributed across a large geographical area and make use of load balancer to offer the best performance. GCP has an interesting feature that allow us to distribute the cluster across multiple regions and automatically sets the lower latency for each client, which makes it a compeling option for regions like Europe and America.

## Monitoring and logging

Our installation do not have a proper monitoring and logging system. Even after installing Minikube dashboard we are not actively monitoring the cluster for performance and getting notified if something goes wrong, we are just seeing the cluster state in realtime with a little data history. For a proper production-ready cluster we need a dedicated tool for observability.

Another important consideration are the logs: all pods and most Kubernetes resources produce logs that can help us to identify infrastructure problems, debug complex bugs in our applications, or even see patterns in usage that can help us to decide infrastructure parameters (CPU, memory usage, for example). There is also the logs from the applications themselves that run in the cluster, that can be outputed to Kubernetes (and gather with a cluster-wide tool) or to directly send the important logs to an external tool.

For monitoring the cluster the open source solution most used is Grafana + Prometheus. Prometheus is a framework for monitoring that gathers application logs and organize them in a server. Grafana is a common tool used for fetching the Prometheus data and use it to create alerts. There are also solutions from the big cloud providers, such as AWS Data Firehose and Azure Insights. Other solutions, using proprietary software, are Datadog and NewRelic. They are usually more feature complete, but are also more expensive.

## Backup and DR

Our Kubernetes cluster does not have any backup setup. To promote it to a production-ready environment, we need to implement a backup strategy. On Kubernetes, if installed in bare-metal, it's important to backup all the ETCD configuration, persistent volumes and the resources used to create the cluster - not the virtual machine itself. The applications should, as much as possible, store persistent data in external databases that have their own backups.

In a real world, however, it's rare to see on-premise non-managed clusters, most of them are running in a Cloud Provider. In this sense it is better to make use of cloud-specific backup solutions, such as AKS backup service. It is important to have multiple backups strategies, for example one every 6 hours but keeping all from last 24, one backup from last week, one backup from last month for 5 years. The backup retention usually follows contracts the company we work on has with clients, ranging usually from 3 to 5 years.

A disaster recover exercise is important to make sure we can recreate our cluster and get our services back online. There are many ways to go about this, but ideally we should start from an empty environment and deploy everything - from infrastructure resources to client-facing applications - in an automated way. A DR exercice can expose shortcomings from current CI/CD solution, inter dependency between applications, teams and process. The usage of Infrastructure-as-code, secret management tools, automated configuration using ArgoCD will help to execute a DR exercise successfully.

## Performance optimizations

When running multiple applications in the same cluster we might need to control memory and cpu usage. Having the applications limits and request close to their real-world usage allows the kubernetes scheduler to be much more efficient, therefore, ensuring performance is enough without costing extra money. In the applications pods definition we should add sections to cpu and memory limits and request, this prevents the application from using too much resources of the cluster.

Another way to improve performance is by enabling autoscaling. Clusters that change too constantly are not ideal, as there is an overhead for spawning/deleting nodes, but at times this might comes handy, like a downscaling process at late night, when system usage is low, or upscaling when there is an important event happening, like a huge sale where traffic increases.

In my personal experience, having fewer bigger nodes is better than many smaller nodes. When nodes are small, Kubernetes has trouble fitting "big applications" in the smaller nodes and ends up creating a new node almost entirely dedicated to that application - or just failing to schedule it. While the new node is unavailable, the application remains in `NOT READY` state, and depending on the cloud provider this can take many minutes.

Finally, we can also improve performance by changing the profile of the nodes. For example, instead of using nodes with a ratio of 2GB of RAM for each CPU, we can have a ratio of 8GB for each CPU. The cost is usually driven by the CPU, so having more memory allow us to schedule more applications, but that depends entirely on the applications profile. It's important to look at the metrics and monitoring to determine the real application profile usage.



