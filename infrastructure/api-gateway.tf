
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
  subnet_id      = oci_core_subnet.public_subnet.id
  display_name   = "fn api gateway"
}



