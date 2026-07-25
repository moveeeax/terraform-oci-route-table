variable "compartment_id" {
  description = "OCID of the compartment in which to create the route table."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN the route table belongs to."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the route table."
  type        = string
}

variable "route_rules" {
  description = <<-EOT
    List of route rules for the table. Defaults to an empty list, so the module creates
    no routes — and in particular no 0.0.0.0/0 route — unless you ask for them.

    For gateway targets (internet, NAT, DRG, local peering) use
    `destination_type = "CIDR_BLOCK"` with a CIDR destination. For a service gateway use
    `destination_type = "SERVICE_CIDR_BLOCK"` with the service's `cidr_block` label
    (for example `all-phx-services-in-oracle-services-network`), never the service OCID.
  EOT
  type = list(object({
    network_entity_id = string
    destination       = string
    destination_type  = optional(string, "CIDR_BLOCK")
    description       = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.route_rules : contains(["CIDR_BLOCK", "SERVICE_CIDR_BLOCK"], r.destination_type)
    ])
    error_message = "destination_type must be CIDR_BLOCK or SERVICE_CIDR_BLOCK."
  }

  validation {
    condition = alltrue([
      for r in var.route_rules : can(cidrhost(r.destination, 0))
      if r.destination_type == "CIDR_BLOCK"
    ])
    error_message = "Every rule with destination_type = \"CIDR_BLOCK\" must set destination to a CIDR block such as \"0.0.0.0/0\" or \"::/0\". A service gateway rule needs destination_type = \"SERVICE_CIDR_BLOCK\" and the service's cidr_block label."
  }

  validation {
    condition = alltrue([
      for r in var.route_rules : !can(cidrhost(r.destination, 0)) && !startswith(r.destination, "ocid1.")
      if r.destination_type == "SERVICE_CIDR_BLOCK"
    ])
    error_message = "Every rule with destination_type = \"SERVICE_CIDR_BLOCK\" must set destination to a service cidr_block label such as \"all-phx-services-in-oracle-services-network\" (data.oci_core_services.this.services[0].cidr_block), not a CIDR block and not a service OCID."
  }

  validation {
    condition     = length(distinct([for r in var.route_rules : lower(r.destination)])) == length(var.route_rules)
    error_message = "Route rule destinations must be unique. OCI rejects a route table that repeats a destination, and a duplicate rule can never take effect."
  }

  validation {
    condition = alltrue([
      for r in var.route_rules : can(regex("^ocid1\\.[a-z0-9]+\\.", r.network_entity_id))
    ])
    error_message = "network_entity_id must be the OCID of the target gateway (starting with \"ocid1.\"), not its display name."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the route table."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the route table, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
