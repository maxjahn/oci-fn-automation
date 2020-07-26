#!/bin/bash

. ./oci_env.sh

export OCI_repo_name="fn-repo"

fn create context oci --provider oracle
fn use context oci
fn update context oracle.profile DEFAULT

fn update context oracle.compartment-id $TF_VAR_oci_compartment_ocid
fn update context api-url https://functions.${TF_VAR_oci_region}.oci.oraclecloud.com
fn update context registry ${TF_VAR_oci_region}.ocir.io/${OCI_storage_tenancy}/${OCI_repo_name}



