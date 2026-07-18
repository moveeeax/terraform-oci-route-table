# terraform-oci-route-table

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
route table within an existing VCN. Route rules are supplied as a typed list and can
target internet, NAT, service, local peering and dynamic routing gateways.

## Usage

```hcl
module "route_table" {
  source = "github.com/cybercapybara/terraform-oci-route-table"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "prod-public-rt"

  route_rules = [
    {
      network_entity_id = var.internet_gateway_id
      destination       = "0.0.0.0/0"
      description       = "Default route to the internet"
    }
  ]

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name             | Description                                                   | Type                | Default | Required |
|------------------|---------------------------------------------------------------|---------------------|---------|:--------:|
| `compartment_id` | OCID of the compartment in which to create the route table.   | `string`            | n/a     |   yes    |
| `vcn_id`         | OCID of the VCN the route table belongs to.                   | `string`            | n/a     |   yes    |
| `display_name`   | Human-readable name for the route table.                      | `string`            | n/a     |   yes    |
| `route_rules`    | List of route rules (network_entity_id, destination, type).   | `list(object(...))` | `[]`    |    no    |
| `freeform_tags`  | Free-form tags applied to the route table.                    | `map(string)`       | `{}`    |    no    |
| `defined_tags`   | Defined tags applied to the route table, keyed `namespace.key`| `map(string)`       | `{}`    |    no    |

## Outputs

| Name           | Description                               |
|----------------|-------------------------------------------|
| `id`           | OCID of the route table.                  |
| `display_name` | Display name of the route table.          |
| `route_rules`  | Route rules configured on the table.      |
| `state`        | Lifecycle state of the route table.       |

## License

[MIT](LICENSE)
