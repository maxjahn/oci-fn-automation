provider "oci" {
  version      = ">= 3.0.0"
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid    = var.oci_user_ocid
  fingerprint  = var.oci_fingerprint
  region       = var.oci_region
}

