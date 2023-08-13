# Azure Terraform architecture for my personal projects

The main purpose of this Terraform architecture is to deploy and manage the Azure resources I want to use for my personal projects. Currently main one is my [homepage](https://github.com/Aapok0/homepage-bulma), which I want to host on a virtual machine with Nginx. At some point I will move on to using an app service or a container, but for now I want to work on my skills with Ansible and Nginx.

The way I arranged the modules and wrote them is a compromise between of the needs of my project and wanting to write scalable code, that could fit into a larger architecture. Scalability and reusability could be improved in many ways, but I don't want to make things too complicated. This code still needs to serve my own purposes.

### Related repositories

- [Homepage version 1](https://github.com/Aapok0/homepage)
- [Homepage version 2](https://github.com/Aapok0/homepage-bulma)
- [Ansible for Nginx webserver](https://github.com/Aapok0/homepage-webserver-ansible)

## Structure

Repository has the following directories and files:

- **compute/** &rarr; compute resource modules
  - **virtual_machine** &rarr; module to create a virtual machine
    - **main.tf**
    - **outputs.tf**
    - **variables.tf**
    - **ssh-config-apply** &rarr; script to add host information to ssh config file
    - **ssh-config-destroy** &rarr; script to remove host information from ssh config file
- **general/** &rarr; general resource modules
  - **budget/** &rarr; module to create a budget
    - **main.tf**
    - **variables.tf**
  - **networks_watcher/** &rarr; module to create a network watcher
    - **main.tf**
    - **variables.tf**
- **policy/** &rarr; policy assignment modules
  - **location/** &rarr; module to create allowed locations policy
    - **main.tf**
    - **variables.tf**
  - **tags/** &rarr; module to create required and inherited tags policy
    - **rg_tags/** &rarr; submodule for the resource group scope
      - **main.tf**
      - **variables.tf**
    - **sub_tags/** &rarr; submodule for the subscription scope
      - **main.tf**
      - **variables.tf**
    - **main.tf**
    - **variables.tf**
  - **vm_sku** &rarr; module to create allowed virtual machine SKUs policy
    - **main.tf**
    - **variables.tf**
- **project/** &rarr; module to create the main wrapper for a project
  - **main.tf**
  - **outputs.tf**
  - **variables.tf**
- **main.tf** &rarr; main file to call modules and other needed resources
- **outputs.tf**
- **terraform.tf** &rarr; terraform and provider versions
- **variables.tf**

The file **terraform.tfvars** should also be created to pass sensitive variables. It is not pushed into this repository. Currently the following variables are passed with it.

```terraform
contact_emails    = ["email1@invalid.com", "email2@invalid.com"]  
ssh_addr_prefixes = ["123.123.123.123", "111.111.111.111"]
admin_user        = "adminuser"
```

## How to use

```bash
# Requires Azure CLI and Terraform (required version 1.5.4 or any patch above that)

# Clone repository and configure to your liking

# Login to your Azure account and switch to preferred subscription, if you have multiple.
az login
az account set --subscription <name-or-id>

# Initialize terraform (in the root of the repository)
terraform init

# Optionally format the code and validate, that it works
terraform fmt
terraform validate

# Create a plan (I prefer using a file)
terraform plan -out tfplan

# If everything looks good, apply to deploy to Azure
terraform apply tfplan
```
