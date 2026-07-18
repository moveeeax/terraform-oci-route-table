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
  description = "List of route rules for the table."
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
