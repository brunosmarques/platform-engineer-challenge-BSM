# Terraform guide

This guide will help you to install, understand and use Terraform locally to configure your local cluster.

## Terraform installation

In our example Terraform is used to configure the local Kubernetes cluster we created in `OPERATOR.md` using MiniKube. To use Terraform we first need to install it, as it's not part of either Windows, MacOS or Linux standard installation. The manual installation steps are:

1. Download the [pre-compiled binary from Hashicorp](https://developer.hashicorp.com/terraform/install)
2. Add the binary to your OS path

It is possible to use Homebrew, Chocolatey and linux distributions repositories to install Terraform. For more information, refeer to the [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

Once installed, we are be able to open any terminal/powershell and run:

````
terraform -version
````

Expected result is similar to:

```
Terraform v1.9.8
on windows_amd64
```

## Files structure

Terraform is a declarative method of creating resources, such as virtual machines, kubernetes namespaces, user credentials and much more. Being declarative means that instead of writing all the steps necessary to achieve a result, like a BASH script, we only write the desired resources in no particular order and Terraform will define the best strategy to achieve that result. Generally, all the resources and Terraform configuration necessary for every project is written in `.tf` files. In our project, we have three files: `main.tf`, `namespaces.tf` and `rbac.tf`.

## main.tf

The `main.tf` file usually only defines the providers we will use, their versions requirements and their configurations. In our case, we'll be using the `kubernetes` provider. The kubernetes provider is referencing a local cluster configuration - not a cluster in some Cloud provider, such as Azure, AWS or GCP - so the kubernetes cluster we apply our project depends on the cluster context configured in our local kube config file.

> WARNING: make sure you have the correct kubernetes context defined in ~/.kube/config. It is set automatically to your newly created cluster in OPERATOR.md if you're using Minikube

#### main.tf - defines required providers and their configuration

```
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

## namespaces.tf

The `namespaces.tf` file has the definition of all the namespaces we want to exist in our local cluster. For example, this is the definition of two code blocks for two namespaces: productA and productB. For now, they don't exist in the cluster because we did not ran Terraform, we're just coding the resources we want Terraform to create and manage for us.

#### namespaces.tf

````
resource "kubernetes_namespace" "pizza" {
  metadata {
    name = "pizza"
  }
}

resource "kubernetes_namespace" "burguer" {
  metadata {
    name = "burguer"
  }
}
````

## rbac.tf

The `rbac.tf` file has the definition of our roles and access permissions. We cannot restrict user access from here because there's no deny rules in Kubernetes RBAC, but we can create a set of permissions to be applied to service accounts, which will make sure the applications do have the permissions they need. In a production cluster we generally restrict users and service accounts access to the minimum, so having the RBAC in place allow us to safely deploy and run the applications without permissions errors. In our case, we are creating:

* A serviceaccount named `pineapple`
* A role named `read-pods` that ensures permission in `pizza` namespace
* A binding between the role and the serviceaccount

#### rbac.tf

````
# ServiceAccount
resource "kubernetes_service_account" "pineapple" {
  metadata {
    name = "pineapple"
    namespace = kubernetes_namespace.pizza.metadata[0].name
  }
}  

# Role
resource "kubernetes_role" "read_pods" {
  metadata {
    name      = "read-pods" 
    namespace = kubernetes_namespace.pizza.metadata[0].name 
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "watch", "list"]
  }
}  

# Binding
resource "kubernetes_role_binding" "pineapple_read_pods" {
  metadata {
    name      = "pineapple_read_pods"
    namespace = kubernetes_namespace.pizza.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.read_pods.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.pineapple.metadata[0].name
    namespace = kubernetes_namespace.pizza.metadata[0].name 
  }
}
````

## Running Terraform

Now that our configuration is in place, we can run Terraform to create resources. Open a terminal/powershell window and go inside the `terraform` folder. Before applying the code, we need to initiate the project. Run:

```
terraform init
```

Expected result:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/kubernetes versions matching ">= 2.0.0"...
- Installing hashicorp/kubernetes v2.33.0...
- Installed hashicorp/kubernetes v2.33.0 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### terraform plan

We will now use `terraform plan` to create a plan for our changes. This step is not mandatory but highly encouraged because it can show mistakes in our configuration without any effect on the infrastructure - nothing changes. In the same folder we were before, we run:

```
terraform plan
```

Expected result:

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # kubernetes_namespace.burguer will be created
  + resource "kubernetes_namespace" "burguer" {
      + id                               = (known after apply)
      + wait_for_default_service_account = false

      + metadata {
          + generation       = (known after apply)
          + name             = "burguer"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

  # kubernetes_namespace.pizza will be created
  + resource "kubernetes_namespace" "pizza" {
      + id                               = (known after apply)
      + wait_for_default_service_account = false

      + metadata {
          + generation       = (known after apply)
          + name             = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

  # kubernetes_role.read_pods will be created
  + resource "kubernetes_role" "read_pods" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "read-pods"
          + namespace        = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + rule {
          + api_groups = [
              + null,
            ]
          + resources  = [
              + "pods",
            ]
          + verbs      = [
              + "get",
              + "list",
              + "watch",
            ]
        }
    }

  # kubernetes_role_binding.pineapple_read_pods will be created
  + resource "kubernetes_role_binding" "pineapple_read_pods" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "pineapple_read_pods"
          + namespace        = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + role_ref {
          + api_group = "rbac.authorization.k8s.io"
          + kind      = "Role"
          + name      = "read-pods"
        }

      + subject {
          + api_group = (known after apply)
          + kind      = "ServiceAccount"
          + name      = "pineapple"
          + namespace = "pizza"
        }
    }

  # kubernetes_service_account.pineapple will be created
  + resource "kubernetes_service_account" "pineapple" {
      + automount_service_account_token = true
      + default_secret_name             = (known after apply)
      + id                              = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "pineapple"
          + namespace        = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

Here we can validate the plan, which consists of creating two namespaces (pizza and burguer), one serviceaccount, one role and one binding. Totaling 5 resouces to add, the plan looks correct. We can now move on to the resources creation.

### terraform apply

We can finally apply the code to create our resources. Once we start the apply, terraform will generate a new plan, and we will have a final moment to validate the changes planned before deciding to apply it or not. To create the resources, we run:

```
terraform apply
```

Expected result:

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # kubernetes_namespace.burguer will be created
  + resource "kubernetes_namespace" "burguer" {
      + id                               = (known after apply)
      + wait_for_default_service_account = false

      + metadata {
          + generation       = (known after apply)
          + name             = "burguer"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

  # kubernetes_namespace.pizza will be created
  + resource "kubernetes_namespace" "pizza" {
      + id                               = (known after apply)
      + wait_for_default_service_account = false

      + metadata {
          + generation       = (known after apply)
          + name             = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

  # kubernetes_role.read_pods will be created
  + resource "kubernetes_role" "read_pods" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "read-pods"
          + namespace        = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + rule {
          + api_groups = [
              + null,
            ]
          + resources  = [
              + "pods",
            ]
          + verbs      = [
              + "get",
              + "list",
              + "watch",
            ]
        }
    }

  # kubernetes_role_binding.pineapple_read_pods will be created
  + resource "kubernetes_role_binding" "pineapple_read_pods" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "pineapple_read_pods"
          + namespace        = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + role_ref {
          + api_group = "rbac.authorization.k8s.io"
          + kind      = "Role"
          + name      = "read-pods"
        }

      + subject {
          + api_group = (known after apply)
          + kind      = "ServiceAccount"
          + name      = "pineapple"
          + namespace = "pizza"
        }
    }

  # kubernetes_service_account.pineapple will be created
  + resource "kubernetes_service_account" "pineapple" {
      + automount_service_account_token = true
      + default_secret_name             = (known after apply)
      + id                              = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + name             = "pineapple"
          + namespace        = "pizza"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

kubernetes_namespace.pizza: Creating...
kubernetes_namespace.burguer: Creating...
kubernetes_namespace.burguer: Creation complete after 0s [id=burguer]
kubernetes_namespace.pizza: Creation complete after 0s [id=pizza]
kubernetes_service_account.pineapple: Creating...
kubernetes_role.read_pods: Creating...
kubernetes_service_account.pineapple: Creation complete after 0s [id=pizza/pineapple]
kubernetes_role.read_pods: Creation complete after 0s [id=pizza/read-pods]
kubernetes_role_binding.pineapple_read_pods: Creating...
kubernetes_role_binding.pineapple_read_pods: Creation complete after 0s [id=pizza/pineapple_read_pods]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

> After finishing the plan, terraform will ask if we want to apply the plan, and it only accepts "yes" as a valid answer. Anything different will cause the plan to be discarted.

That's it, terraform has finished without errors. Notice that it did not matter the ordering of the resources in the files, Terraform first created the namespaces and then the serviceaccount, role and finally the binding. It wouldn't be possible to do in a reverse order, as the binding depends on the role/serviceaccount and they depend on the namespaces. This dependency complexity can get a lot more complicated, but thankfuly Terraform manages that for us.

## Verifying resources created

In previous steps we created a Kubernetes cluster configuration using Terraform. That consists of two namespaces, one serviceaccount, one role and one binding. We will now verify those resources in the cluster using `kubectl`.

### namespaces

```
kubectl get ns
```

Expected result:

````
NAME                   STATUS   AGE
(...)
burguer                Active   76m
pizza                  Active   76m
````

### serviceaccount

```
kubectl get serviceaccount -A
```

Expected result:

````
NAMESPACE              NAME                                          SECRETS   AGE
(...)
pizza                  pineapple                                     0         78m
````

### role

```
kubectl get role -A
```

Expected result:

````
NAMESPACE              NAME                                             CREATED AT
(...)
pizza                  read-pods                                        2024-11-24T15:47:58Z
````

### binding

```
kubectl get rolebinding -A
```

Expected result:

````
NAMESPACE              NAME                                                ROLE                                                  AGE
(...)
pizza                  pineapple_read_pods                                 Role/read-pods                                        82m
````

### Testing the access

We can now verify the effectiveness of our RBAC. We created one serviceaccount `pinapple` in `pizza` namespace, and we bind it to a role that allows for reading pods in `pizza` namespace. So this serviceaccount should be able to read pods in `pizza`, but it should not read pods in `burguer` namespace. We use the `can-i` command to simulate the usage of the serviceaccount in different conditions:

Can `pinapple` get pods in `pizza` namespace?

```
kubectl auth can-i get pods --as=system:serviceaccount:pizza:pineapple -n pizza
```

Result:

````
yes
````

Can `pinapple` get pods in `burguer` namespace?

```
kubectl auth can-i get pods --as=system:serviceaccount:pizza:pineapple -n burguer
```

Result:

````
no
````

We have now successfuly verified our RBAC permissons using `kubectl auth can-i`.

## Modifying existing resources

Once we ran terraform it generated some files in our project root folder. They represent, among other things, the state of the resources. By reading at the state files Terraform can determine what resources have been applied and what are their values. This means that on a next run it will not recreate unchanged resources. If something is removed from code but exists in the state, Terraform will attempt to safely remove the resources it has previously created.

However, changing or removing code can create undesired situations, especially when there are things deployed in the infrastructure that are unknow to Terraform. For example, let's say we manually deployed an application called `3Brasseurs` in burguer namespace without using Terraform. Terraform isn't aware of the existance of this application. Now we will attempt to rename the namespace from `burguer`  to `fries`. We change namespace.tf to:

```
(...)
resource "kubernetes_namespace" "burguer" {
  metadata {
    name = "fries" # Previously "burguer"
  }
}
(...)
```

And this is the result of `terraform plan`:

```
# kubernetes_namespace.burguer must be replaced
-/+ resource "kubernetes_namespace" "burguer" {
      ~ id                               = "burguer" -> (known after apply)
        # (1 unchanged attribute hidden)

      ~ metadata {
          - annotations      = {} -> null
          ~ generation       = 0 -> (known after apply)
          - labels           = {} -> null
          ~ name             = "burguer" -> "fries" # forces replacement
          ~ resource_version = "38328" -> (known after apply)
          ~ uid              = "5b1a984b-b8d8-428d-a6e9-51c70f22a5b2" -> (known after apply)
            # (1 unchanged attribute hidden)
        }
    }
```

The problem here is that not only Terraform is not aware we have an application running in `burger` namespace, it cannot rename a namespace due to Kubernetes API restrictions. The solution proposed by Terraform is to delete the old `burguer` namespace and to create a new one named `fries`. This, however, will delete our application `3Brasseurs` with all its data, and it will not recreate it on the new namespace.

We can avoid this issue by adding a lifecycle block in the resource. This will prevent the destruction of the resource, causing the plan/apply to fail, but saving us from deleting the critical resource.

````
lifecycle {
   prevent_destroy = true
}
````

New plan with lifecycle:

```
(...)
Plan: 0 to add, 0 to change, 5 to destroy.
╷
│ Error: Instance cannot be destroyed
│
│   on namespaces.tf line 7:
│    7: resource "kubernetes_namespace" "burguer" {
│
│ Resource kubernetes_namespace.burguer has lifecycle.prevent_destroy set, but the plan calls for this resource to be destroyed. To
│ avoid this error and continue with the plan, either disable lifecycle.prevent_destroy or reduce the scope of the plan using the
│ -target option.
```

Some resources do support changes without recreation, like the Role permission. For example, here is a plan to remove "watch" verb from Role `read-pods` permissions:

```
# kubernetes_role.read_pods will be updated in-place
  ~ resource "kubernetes_role" "read_pods" {
        id = "pizza/read-pods"

      ~ rule {
          ~ verbs          = [
              - "watch",
                # (2 unchanged elements hidden)
            ]
            # (3 unchanged attributes hidden)
        }

        # (1 unchanged block hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Wherever we are changing or deleting resources in Terraform, we need to be aware of the implications of it on the entire system, and not only rely on Terraform plan information. That's why many companies use tools to incorporate CI/CD process closer to the infrastructure definition.

On the other hand, adding resources is often a non-destructive operation. If we want to create a namespace `poutine` alongside the other two, it will not affect the existing resources. Even better, Terraform plan is not going to change any of the existing resource, only the new one will be created. Example:

New namespace code block:

```
resource "kubernetes_namespace" "poutine" {
  metadata {
    name = "poutine"
  }
}
```

Terraform plan:

````
kubernetes_namespace.pizza: Refreshing state... [id=pizza]
kubernetes_namespace.burguer: Refreshing state... [id=burguer]
kubernetes_service_account.pineapple: Refreshing state... [id=pizza/pineapple]
kubernetes_role.read_pods: Refreshing state... [id=pizza/read-pods]
kubernetes_role_binding.pineapple_read_pods: Refreshing state... [id=pizza/pineapple_read_pods]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # kubernetes_namespace.poutine will be created
  + resource "kubernetes_namespace" "poutine" {
      + id                               = (known after apply)
      + wait_for_default_service_account = false

      + metadata {
          + generation       = (known after apply)
          + name             = "poutine"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
````

By managing the infrastructure as code we can push it to a GIT repository and open the possibility of any developer to create a PullRequest, making the interaction between developers and infrastructure managers straightforward, repeteable and auditable. By linking the PRs with a ticket system we can track every part of the infrastructure to its own story and requirements.
