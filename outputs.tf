output "id" {
  description = "OCID of the route table."
  value       = oci_core_route_table.this.id
}

output "display_name" {
  description = "Display name of the route table."
  value       = oci_core_route_table.this.display_name
}

output "route_rules" {
  description = "Route rules configured on the table."
  value       = oci_core_route_table.this.route_rules
}

output "state" {
  description = "Lifecycle state of the route table."
  value       = oci_core_route_table.this.state
}
