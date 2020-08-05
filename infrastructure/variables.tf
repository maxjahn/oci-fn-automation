variable "oci_tenancy_ocid" {
}

variable "oci_user_ocid" {
}

variable "oci_fingerprint" {
}

variable "oci_compartment_ocid" {
}

variable "oci_region" {
  default = "eu-frankfurt-1"
}

variable "oci_cidr_vcn" {
  default = "10.0.0.0/16"
}

variable "oci_cidr_private_subnet" {
  default = "10.0.1.0/24"
}

variable "oci_cidr_public_subnet" {
  default = "10.0.2.0/24"
}

variable "oci_cidr_api_subnet" {
  default = "10.0.3.0/29"
}

variable "ssh_public_key" {
}

