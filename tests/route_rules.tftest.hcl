# Run with `terraform test`. The mock_provider block below needs Terraform >= 1.7
# (or OpenTofu >= 1.7); the module itself still only requires >= 1.5.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"
  display_name   = "test-rt"
}

run "no_routes_are_created_by_default" {
  command = plan

  assert {
    condition     = length(oci_core_route_table.this.route_rules) == 0
    error_message = "The module must not create any route rule by default; an implicit 0.0.0.0/0 route would make every attached subnet public."
  }
}

# Uses `command = apply` (against the mock provider) because the provider marks
# route_rules as computed, so its final value is unknown during plan.
run "every_rule_reaches_the_resource" {
  command = apply

  variables {
    route_rules = [
      {
        network_entity_id = "ocid1.internetgateway.oc1.phx.aaaaaaaaexampleigw"
        destination       = "0.0.0.0/0"
        description       = "default route"
      },
      {
        network_entity_id = "ocid1.natgateway.oc1.phx.aaaaaaaaexamplenat"
        destination       = "10.1.0.0/16"
      },
      {
        network_entity_id = "ocid1.servicegateway.oc1.phx.aaaaaaaaexamplesgw"
        destination       = "all-phx-services-in-oracle-services-network"
        destination_type  = "SERVICE_CIDR_BLOCK"
      },
    ]
  }

  assert {
    condition     = length(oci_core_route_table.this.route_rules) == 3
    error_message = "All three route rules must be sent to the provider; none may be silently dropped."
  }

  assert {
    condition = length([
      for r in oci_core_route_table.this.route_rules : r
      if r.destination == "all-phx-services-in-oracle-services-network" && r.destination_type == "SERVICE_CIDR_BLOCK"
    ]) == 1
    error_message = "The service gateway rule must keep destination_type = SERVICE_CIDR_BLOCK."
  }

  assert {
    condition = length([
      for r in oci_core_route_table.this.route_rules : r
      if r.destination == "10.1.0.0/16" && r.destination_type == "CIDR_BLOCK"
    ]) == 1
    error_message = "destination_type must default to CIDR_BLOCK when it is omitted."
  }
}

run "rejects_unknown_destination_type" {
  command = plan

  variables {
    route_rules = [{
      network_entity_id = "ocid1.internetgateway.oc1.phx.aaaaaaaaexampleigw"
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR"
    }]
  }

  expect_failures = [var.route_rules]
}

run "rejects_service_label_declared_as_cidr_block" {
  command = plan

  variables {
    route_rules = [{
      network_entity_id = "ocid1.servicegateway.oc1.phx.aaaaaaaaexamplesgw"
      destination       = "all-phx-services-in-oracle-services-network"
    }]
  }

  expect_failures = [var.route_rules]
}

run "rejects_service_ocid_as_service_cidr_block_destination" {
  command = plan

  variables {
    route_rules = [{
      network_entity_id = "ocid1.servicegateway.oc1.phx.aaaaaaaaexamplesgw"
      destination       = "ocid1.service.oc1.phx.aaaaaaaaexampleservice"
      destination_type  = "SERVICE_CIDR_BLOCK"
    }]
  }

  expect_failures = [var.route_rules]
}

run "rejects_cidr_as_service_cidr_block_destination" {
  command = plan

  variables {
    route_rules = [{
      network_entity_id = "ocid1.servicegateway.oc1.phx.aaaaaaaaexamplesgw"
      destination       = "134.70.0.0/16"
      destination_type  = "SERVICE_CIDR_BLOCK"
    }]
  }

  expect_failures = [var.route_rules]
}

run "rejects_malformed_cidr_destination" {
  command = plan

  variables {
    route_rules = [{
      network_entity_id = "ocid1.internetgateway.oc1.phx.aaaaaaaaexampleigw"
      destination       = "10.0.0.0/33"
    }]
  }

  expect_failures = [var.route_rules]
}

run "rejects_duplicate_destinations" {
  command = plan

  variables {
    route_rules = [
      {
        network_entity_id = "ocid1.internetgateway.oc1.phx.aaaaaaaaexampleigw"
        destination       = "0.0.0.0/0"
      },
      {
        network_entity_id = "ocid1.natgateway.oc1.phx.aaaaaaaaexamplenat"
        destination       = "0.0.0.0/0"
      },
    ]
  }

  expect_failures = [var.route_rules]
}

run "rejects_network_entity_id_that_is_not_an_ocid" {
  command = plan

  variables {
    route_rules = [{
      network_entity_id = "prod-internet-gateway"
      destination       = "0.0.0.0/0"
    }]
  }

  expect_failures = [var.route_rules]
}
