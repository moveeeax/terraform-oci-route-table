provider "oci" {}

module "route_table" {
  source = "../.."

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "example-rt"

  route_rules = [
    {
      network_entity_id = var.internet_gateway_id
      destination       = "0.0.0.0/0"
      description       = "Default route to the internet"
    }
  ]

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example route table into."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN to attach the example route table to."
  type        = string
}

variable "internet_gateway_id" {
  description = "OCID of an internet gateway used as the default route target."
  type        = string
}

output "route_table_id" {
  value = module.route_table.id
}
