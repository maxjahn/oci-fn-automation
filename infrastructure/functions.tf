resource "oci_identity_user" "auto_user" {
  compartment_id = var.oci_tenancy_ocid
  description    = "Automation User"
  name           = "auto-user"
}

resource "oci_identity_user_group_membership" "app_auto_group_membership" {
  group_id = oci_identity_group.fn_usr_grp.id
  user_id  = oci_identity_user.auto_user.id
}

resource "oci_functions_application" "automation_app" {
  compartment_id = var.oci_compartment_ocid
  display_name   = "automation-app"
  subnet_ids     = [oci_core_subnet.public_subnet.id, oci_core_subnet.private_subnet.id]
}

data "oci_objectstorage_namespace" "os_ns" {
  compartment_id = var.oci_compartment_ocid
}

resource "oci_objectstorage_bucket" "img_bucket" {
  compartment_id        = var.oci_compartment_ocid
  name                  = "img"
  namespace             = data.oci_objectstorage_namespace.os_ns.namespace
  object_events_enabled = true
  access_type           = "ObjectRead"
}





