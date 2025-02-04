# Nomad Deployment

We are now going to install Consul, Vault, and Nomad on the Hashistack
nodes. The are the main components that will make the Hashistack work.

> [!NOTE]  
> **_Ansible Script:_** [15_nomad_deployment.yaml](../15_nomad_deployment.yaml)

#### Most noticable / important variables

| Variable                    | Default value          | Description                            |
| --------------------------- | ---------------------- | -------------------------------------- |
| hashicorp_product_selection | `consul, nomad, vault` | The HashiCorp products we will install |

#### Variable Files

-   vars/general/main.yaml
-   vars/general/hashi_nodes.yaml
-   vars/hashicorp/main.yaml

If you are using Ansible, set these variables appropriately, and run the
script now. Once it is done, go to [Next Step](#next-step).

If you want to run the steps manually, continue here.

> [!IMPORTANT]  
> You will need to run each of these steps on each of the Hashistack
> nodes unless otherwise mentioned.

## Step 1:

## Next Step

[Nomad Vault Integration](16_nomad_vault_integratiion.md)

## Reference Links

-   https://github.com/chrisvanmeer/at-hashi-demo
