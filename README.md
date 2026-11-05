# terraform-oci-route-table

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
route table within an existing VCN. Route rules are supplied as a typed list and can
target internet, NAT, service, local peering and dynamic routing gateways.

## Usage

```hcl
module "route_table" {
  source = "github.com/moveeeax/terraform-oci-route-table?ref=v1.0.0"

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

A runnable example lives in [`examples/basic`](examples/basic). Note that the example
above attaches a `0.0.0.0/0` route to an internet gateway, which makes every subnet
using this route table publicly routable. `route_rules` defaults to `[]`, so the module
never adds a default route on its own — you always opt in.

### Route rule destinations

`destination_type` decides how OCI interprets `destination`, and getting it wrong is the
easiest way to build a route table that applies cleanly and routes nothing:

| Target                                        | `destination_type`    | `destination`                                                        |
|-----------------------------------------------|-----------------------|----------------------------------------------------------------------|
| internet / NAT / DRG / local peering gateway   | `CIDR_BLOCK` (default)| a CIDR block, e.g. `0.0.0.0/0`, `10.1.0.0/16`, `::/0`                |
| service gateway                                | `SERVICE_CIDR_BLOCK`  | the service's `cidr_block` label, e.g. `all-phx-services-in-oracle-services-network` |

For a service gateway, take the label from the services data source — not the service OCID,
and not the CIDR range the label happens to expand to:

```hcl
data "oci_core_services" "objectstorage" {
  filter {
    name   = "name"
    values = ["OCI .* Object Storage"]
    regex  = true
  }
}

module "service_route_table" {
  source = "github.com/moveeeax/terraform-oci-route-table?ref=v1.0.0"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "prod-private-rt"

  route_rules = [
    {
      network_entity_id = var.service_gateway_id
      destination       = data.oci_core_services.objectstorage.services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      description       = "Object Storage via the service gateway"
    }
  ]
}
```

`route_rules` is validated at plan time. The module rejects a rule whose `destination`
does not match its `destination_type`, a `network_entity_id` that is not an OCID, and two
rules that share a destination (OCI rejects duplicate destinations at apply time).

## Tests

```
terraform test
```

The suite in [`tests/`](tests) runs against a mocked OCI provider, so it needs no
credentials and no network. `mock_provider` requires Terraform/OpenTofu >= 1.7; the
module itself still only requires >= 1.5.

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
| `route_rules`    | Route rules (`network_entity_id`, `destination`, `destination_type`, `description`). Validated — see above. | `list(object(...))` | `[]`    |    no    |
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
