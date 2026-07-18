resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = var.display_name

  dynamic "route_rules" {
    for_each = var.route_rules
    content {
      network_entity_id = route_rules.value.network_entity_id
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      description       = route_rules.value.description
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
