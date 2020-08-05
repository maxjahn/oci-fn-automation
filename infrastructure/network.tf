resource "oci_core_virtual_network" "app_vcn" {
  cidr_block     = var.oci_cidr_vcn
  dns_label      = "appvcn"
  compartment_id = var.oci_compartment_ocid
  display_name   = "app-vcn"
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block        = var.oci_cidr_private_subnet
  compartment_id    = var.oci_compartment_ocid
  vcn_id            = oci_core_virtual_network.app_vcn.id
  display_name      = "private-subnet"
  dns_label         = "privsubnet"
  security_list_ids = [oci_core_security_list.private_sl.id]
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block        = var.oci_cidr_public_subnet
  compartment_id    = var.oci_compartment_ocid
  vcn_id            = oci_core_virtual_network.app_vcn.id
  display_name      = "public-subnet"
  dns_label         = "pubsubnet"
  security_list_ids = [oci_core_security_list.app_sl.id]
}



resource "oci_core_internet_gateway" "app_igw" {
  display_name   = "app-internet-gateway"
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.app_vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_virtual_network.app_vcn.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.app_igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "app_sl" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.app_vcn.id
  display_name   = "app-security-list"

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = "22"
      max = "22"
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}


resource "oci_core_security_list" "private_sl" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_virtual_network.app_vcn.id
  display_name   = "private-security-list"

  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "1"
  }

  ingress_security_rules {
    source   = "10.0.0.0/16"
    protocol = "6"

    tcp_options {
      min = "22"
      max = "22"
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
}

