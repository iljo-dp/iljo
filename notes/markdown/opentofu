Title: Infrastructure as Code: How We Reimagined Our Cloud Deployment Pipeline with OpenTofu
Category: generalPhil
Date: 2024-11-28

# Introduction
Now, I've got to be honest, I was a bit nervous about this at first because Terraform has been a staple in our workflow for quite some time. But after diving into OpenTofu and seeing its capabilities, I'm really excited about the possibilities.

First off, for those who might not know, Terraform is an infrastructure as code software tool created by HashiCorp. It allows you to safely and predictably create, change, and improve infrastructure. OpenTofu, on the other hand, is an open-source infrastructure as code software tool that is a fork of Terraform. It's maintained by a community and is completely open-source, which aligns well with our commitment to open-source technologies.

So, why did we make the switch? Well, there were a few reasons. First, HashiCorp had introduced some licensing changes that made us a bit uneasy about the future direction of Terraform. We wanted a solution that was completely open-source and wouldn't be subject to potential licensing changes down the line. OpenTofu provided that assurance.

Another reason was the active community behind OpenTofu. Since it's a fork, it inherits all the features and improvements from Terraform, but with the added benefit of being developed by a community that's focused on keeping it open and free. This alignment with our values was a big plus.

Now, moving from Terraform to OpenTofu wasn't without its challenges. One of the main hurdles was updating our CI/CD pipeline to work with OpenTofu instead of Terraform. Our pipeline is crucial; it's what automates the process of validating, planning, and applying changes to our infrastructure.

Let me walk you through our pipeline setup. We use GitLab CI/CD, which is integrated seamlessly with OpenTofu through the GitLab ToFu tool. This tool provides commands like `gitlab-tofu fmt`, `validate`, `plan`, and `apply`, which are analogous to their Terraform counterparts.

Here's a snippet from our `.gitlab-ci.yml` file that shows how we set up the pipeline for OpenTofu:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/opentofu/validate-plan-apply@0.42.0-rc2
    inputs:
      opentofu_version: 1.8.5
      root_dir: ./opentofu
      state_name: infrastructure
    rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

  - component: $CI_SERVER_FQDN/components/opentofu/validate-plan@0.42.0-rc2
    inputs:
      opentofu_version: 1.8.5
      root_dir: ./opentofu
      state_name: infrastructure
    rules:
      - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
        when: always
```

In this configuration, we're including predefined components for OpenTofu validation, planning, and applying changes. These components are versioned and can be included directly in our pipeline configuration. This modular approach makes our pipeline more maintainable and scalable.

One of the key differences we noticed when switching to OpenTofu was the need to update our state management. OpenTofu uses a similar state management system to Terraform, but since it's a separate project, we had to ensure that our state files were compatible or migrate them accordingly.

One of the biggest hurdles was the http backend. We have a very special way of maneging these things since we use ci/cd runners. Our tf state is stored somewhere that isn't the runner or accasible, and so for terraform we had our own way of managing this. We had to make sure that this was still possible with OpenTofu. Which it wasn't, so we needed to make some changes to our http backend.

Another aspect that required attention was the providers we use. Since OpenTofu is a fork of Terraform, most providers are compatible out of the box. However, we had to verify that the versions of the providers we were using were compatible with the version of OpenTofu we adopted.

In our `versions.tf` file, we specify the required version of OpenTofu and the versions of the providers we use:

```hcl
terraform {
  required_version = ">= 1.8.5"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.9.2"
    }
  }
}
```
Due to our switch to opentofu we had the ability to use the latest version of the vsphere provider, which was a big plus for us.
We also finally could move to something else then tf 1.5.7 which allowed for more features and better performance.

Now, let's talk about how we structure our infrastructure code. We've organized our code into modules to promote reusability and modularity. For example, we have a module for creating virtual machines, which abstracts away the complexities of configuring VMs in vSphere.

Here's a look at our `modules/virtual_machine/main.tf`:

```hcl
resource "vsphere_virtual_machine" "vm" {
  name                             = var.vm_config.name
  resource_pool_id                 = lookup(var.resource_pools, var.vm_config.resource_pool).id
  datastore_id                     = lookup(var.datastores, var.vm_config.datastore).id
  num_cpus                         = var.vm_config.cpus
  memory                           = var.vm_config.memory
  guest_id                         = lookup(var.templates, var.vm_config.template).guest_id
  scsi_type                        = lookup(var.templates, var.vm_config.template).scsi_type
  firmware                         = "efi"

  network_interface {
    network_id   = lookup(var.networks, var.vm_config.network).id
    adapter_type = lookup(var.templates, var.vm_config.template).network_interface_types[0]
  }

  disk {
    label            = "Hard disk 1"
    size             = var.vm_config.disk_size
    thin_provisioned = true
  }

  clone {
    template_uuid = lookup(var.templates, var.vm_config.template).id
  }

  extra_config = {
    "guestinfo.metadata"          = base64encode(data.template_file.metadata.rendered)
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = base64encode(data.template_file.userdata.rendered)
    "guestinfo.userdata.encoding" = "base64"
  }

  lifecycle {
    ignore_changes = [hv_mode, ept_rvi_mode, extra_config]
  }
}
```

This module allows us to define virtual machines with various configurations, including CPU, memory, disk size, and network settings. It also handles the provisioning of GPUs if needed, using Ansible playbooks.

In our `opentofu` directory, we have the main configuration files that reference these modules and define the infrastructure to be deployed. For example, in `opentofu/vms.tf`, we have:

```hcl
module "vic" {
  source = "../modules/virtual_machine"
  providers = {
    vsphere = vsphere.staging
  }

  for_each = local.vic_vms

  vm_config      = each.value
  resource_pools = local.resource_pools_staging
  datastores     = local.datastores_staging
  networks       = local.networks_staging
  templates      = local.templates_staging
}
```

This file uses the virtual machine module to create multiple VMs based on configurations defined in a JSON file (`vic.json`), which is read and processed in `data.tf` and `locals.tf`.

The transition to OpenTofu has been smoother than expected, thanks to the similarities with Terraform and the active community support. We've been able to maintain our existing workflows while gaining the benefits of an open-source solution. And also implement some new features that we couldn't do with Terraform.

Looking ahead, we're excited about the potential to contribute back to the OpenTofu project and participate in its development. We're also exploring more advanced features of OpenTofu, such as workspaces, to further enhance our infrastructure management.

In conclusion, switching from Terraform to OpenTofu has been a positive step for our team. It has allowed us to continue leveraging the power of infrastructure as code while ensuring that our tools remain open and community-driven. If you're considering a similar move, I'd highly recommend exploring OpenTofu and seeing how it can benefit your infrastructure management


note, code snippets shown are parts of the actual codebase, but have been modified to be more generic and not show any sensitive information, and hide some of the complexity of the codebase.
