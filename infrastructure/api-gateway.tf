
resource "oci_core_subnet" "api_subnet" {
  cidr_block        = var.oci_cidr_api_subnet
  compartment_id    = var.oci_compartment_ocid
  vcn_id            = oci_core_virtual_network.app_vcn.id
  display_name      = "api-subnet"
  dns_label         = "apisubnet"
  security_list_ids = [oci_core_security_list.api_sl.id]
}

resource "oci_core_security_list" "api_sl" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.app_vcn.id
  display_name   = "api-security-list"

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = "80"
      max = "80"
    }
  }
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = "443"
      max = "443"
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}

resource "oci_identity_policy" "fn_api_gw_policy" {
  compartment_id = var.oci_tenancy_ocid
  description    = "policy for api gatway"
  name           = "fn-api-gw-policy"
  depends_on = [
    oci_identity_group.fn_usr_grp,
  ]
  statements = [
    "allow group fn-usr-grp to manage api-gateway-family in compartment id ${var.oci_compartment_ocid}",
    "allow any-user to use functions-family in tenancy where ALL { request.principal.type= 'ApiGateway' , request.resource.compartment.id = '${var.oci_compartment_ocid}' }",
  ]
}

resource "oci_apigateway_gateway" "fn_api_gateway" {
  compartment_id = var.oci_compartment_ocid
  endpoint_type  = "PUBLIC"
  subnet_id      = oci_core_subnet.api_subnet.id
  display_name   = "fn api gateway"
}




