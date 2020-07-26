#!/bin/bash


export OCI_AUTH_TOKEN=`oci iam auth-token create --description fn-access --user-id $OCI_automation_user_ocid | jq '.data|.token' | tr -d \"`

echo "=== docker login auth token ${OCI_AUTH_TOKEN} ==="
docker login ${TF_VAR_oci_region}.ocir.io -u ${OCI_storage_tenancy}/${OCI_automation_user}
