# How to create a kubernetes namespace using Terraform

We are now familiar with MiniKube and Terraform to create our infrastructure. Let's assume this entire configuration is hosted in a Github repository, this has many advantages:

* It can be integrated with automated deploy systems, such as Terraform Cloud or Spinnaker
* It can be viewed and audited by any user with access to the github repository
* It can trace back all the changes in the infrastructure to a ticket system by controlling PRs merged to main
* It can enforces an infrastructure change process (each change needs to be valid to be applied)
* It can integrate with monitoring tools and notify new releases in a variety of channels

In other words, having the infrastructure defined as code and hosted in a common repository can bring developers and infrastructure engineers closer in the resolution of problems and changes. As a developer, we can start to propose and request many infrastructure resources to the infrastructure platform team, such as:

## How to create a new namespace

To create a new Kubernetes namespace you can submit a PR to the infrastructure management team. This PR should include a kubernetes_namespace terraform block similar to what we created in our Terraform guide. If the applications are not deployed via Terraform, which is most likely the case because there are better tools for this (ArgoCD, Github CI/CD), it's a good idea to include a lifecycle parameter to prevent the accidental namespace destruction. If you need to rename a namespace, submit a PR to create the new one but don't delete the old namespace - keep both until you've migrated all the workload - and then submit a second PR to delete the old namespace.

You can expect the platform team to analyse your request and to reflect on its legitimacy. If the proposed namespace makes sense for the organization, and the PRs are completed, well documented and follow the best practices, the new namespace should not take long to be available to use. It is important to also reflect on the RBAC permissions to be created for the new namespace.

### Why use multiple namespaces?

There are different strategies when it comes to multiple namespaces. One common use is to have dev and stage environments segregated, so we can have the same application names and rules applied to different namespaces. This usage is more focused on cost-saving, though.

Another option is to use namespaces to separate the resources from one company's product to another - so having them splitted by namespace allows a company to better secure the cluster access, giving permission to users to only the resources they manage.

A third option, as simple as it sounds, it's to separate the cluster into tribes or teams namespaces. Each team has a dedicated namespace where it can experiment independently from the others, so it reduces the impact from one to the other, especially accidentally.

## How to change RBAC permissions

In our Terraform configuration we setup a basic RBAC Role to a serviceaccount. A RBAC can be applied not only to a serviceaccount, but to a group of serviceaccounts, making our effort to control applications permissions more efficient than creating one custom RBAC to each application.

To create an RBAC, make sure your PR contains three parts:

1. The subject (who or what is going to have permissions added)
2. The Role (what permissions will be added - verbs, resources and namespaces)
3. The RoleBinding (the link between the subject and the Role)

For example, it is a good practice to deny secrets reading to all users, but we can create an RBAC clusterRole that we reuse to every subject that needs secrets reading. For more use cases and examples, please refeer to the [official documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).
