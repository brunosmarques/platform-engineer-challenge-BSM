# Kubernetes cluster scalability

Minikube starts by default one single cluster node. However, for many use cases such as testing blue-green deployments, failovers and load balancing it is necessary to have more than one node at the same cluster. Having more nodes is referred as `horizontal scaling` while having more/less powerful nodes is referred as `vertical scaling`.

Not all nodes are made equal in Kubernetes - there are ways to prevent applications from running in some nodes. This are taints and tolerations, and they can be used for running a subset of AI applications in a given group of nodes with GPU, for example. Production clusters usually separates the cluster control plane to the user application plane (the workload), and this is done by using taints.

This is a single cluster scalability, which already adds a lot of flexibility to our solution. But it is possible to have multiple clusters, deployed in multiple regions, sometimes even across different cloud providers, all working together to be as reliable as possible for critical applications. The following sections discuss some aspects of multiple clusters scalability.

## Managing multiple clusters in Terraform

When managing multiple clusters in Terraform we can make usage of some exceptional tools. It is important to have a reliable template, and in Terraform we can use modules to create our cluster definition. A module can specify a number of input variables to be used, and with that we can use the same template for creating different clusters sizes for different environments, for example. If we have access to Terraform cloud it's even better, we can setup a GIT repository to serve as source code and create a custom module in Terraform Registry, where we can create releases with versioning to the module linked to different repository commits. This allow us to experiment more with the module and only move on the resources that are created with the module templace once we're certain to not create any problems. We can also execute the migration in different batches, moving at first just a couple of resources and then moving most of them later.

Another option commonly used is the tfvars files. This option is even more adaptative than the module because it generates different values for the entire workspace. Put the tfvars together with multiple terraform workspaces (each with a different tfvars input) and you can manage multiple kubernetes clusters from a single repository.

## RBAC best practices

As discussed before, RBAC can only be used to grant permission, never to remove or deny permissions. That's why it's important to follow the principle of "least privilege", meaning the users have strictly only the permissions they need, nothing more. In the context of Kubernetes, this means the usage of RoleBindings instead of cluster-level ClusterRoleBindings - restricting the access to each namespace. Other good practices is to not use wildcard ( * ) in Roles permissions, even with extensive verbs lists.

Having all permissions centralized in one repository means we can leverage most the advantages we discussed in `USER.md` to our access management. Not only that, if the cluster provider is one Cloud platform, such as Azure or AWS, we can bind user groups to policies to access the cluster while keeping the configuration visible in the GIT provider as it does not contain any sensible data. New clusters deployed with the same template/module or script will replicate the permissions, ensuring the clusters correctness.

## Automation tools and scripts

The first step of a cluster creation is the resource allocation and initial setup. This step is usually done via Terraform, but it does not mean the cluster is ready. Many times we need to add custom resources, secrets, config maps, and those resources are considered the configuration of the cluster. To facilitate the scalability of the clusters we need to think of making the second step easy, reliable and reproduceable.

A simple way of making it is via script, like bash, but this has many downsides. Even with complex bash scripting there are problems with unexpected errors, exceptions and general failures that can stops the script in a middle of an operation. It also grows bigger and slower as the number of configurations grow, and needs constant tweaking to keep it updated - it's a never ending maintence project.

A better way is to have all our configuration coded and ready to be applied in a GIT repository and to use a CD tool to automate it's application. ArgoCD is probably the best tool for this today, being one of the stars on [CNCF Landscape](https://landscape.cncf.io/), followed by Flux. These tools can not only apply the configuration, but they are constantly watching for changes in the cluster and/or the files, and can even auto-apply the changes if necessary. We can also use them as temporary overwrites as a quick debug or break-glass mechanism. Inside ArgoCD we can set multiple applications, each with a specific owner team and set of resources in the kubernetes cluster. This makes management much easier because we can quickly see all the resources for any of our applications and have a panorama about its health. Managing multiple clusters without a configuration tool is not a good experience.



