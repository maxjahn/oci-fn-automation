
resource "oci_identity_policy" "faas_root_policy" {
  compartment_id = var.oci_tenancy_ocid
  description    = "policy required for faas"
  name           = "faas-root-policy"
  statements = [
    "allow service FaaS to read repos in tenancy",
    "allow service FaaS to use virtual-network-family in tenancy",
  ]
}

resource "oci_identity_group" "fn_usr_grp" {
  compartment_id = var.oci_tenancy_ocid
  description    = "User group for fn"
  name           = "fn-usr-grp"
}

resource "oci_identity_policy" "fn_usr_grp_policy" {
  compartment_id = var.oci_tenancy_ocid
  description    = "policy for fn-usr-grp"
  name           = "fn-usr-grp-policy"
  depends_on = [
    oci_identity_group.fn_usr_grp,
  ]
  statements = [
    "allow group fn-usr-grp to manage repos in tenancy",
    "allow group fn-usr-grp to use virtual-network-family in tenancy",
    "allow group fn-usr-grp to manage functions-family in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to read metrics in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to read objectstorage-namespaces in compartment id ${var.oci_compartment_ocid}",
    "allow group fn-usr-grp to use cloud-shell in compartment id ${var.oci_compartment_ocid}",
  ]
}

resource "oci_identity_dynamic_group" "fn_dyn_grp" {
  compartment_id = var.oci_tenancy_ocid
  description    = "dynamic group for functions"
  matching_rule  = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${var.oci_compartment_ocid}'}"
  name           = "fn-dyn-grp"
}

resource "oci_identity_policy" "fn_dyn_policy" {
  compartment_id = var.oci_tenancy_ocid
  description    = "policy for fn-dyn-grp"
  name           = "fn-dyn-grp-policy"
  depends_on = [
    oci_identity_dynamic_group.fn_dyn_grp
  ]
  statements = [
    "allow dynamic-group fn-dyn-grp to manage object-family in compartment id ${var.oci_compartment_ocid}",
    "allow dynamic-group fn-dyn-grp to use all-resources in compartment id ${var.oci_compartment_ocid}",
  ]
}



