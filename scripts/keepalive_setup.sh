#!/bin/bash

export OCI_vantage_points='["azr-dub"]'

export OCI_fn_fun_ocid=`oci fn function list \
--application-id $OCI_auto_app_ocid \
| jq '.data[] | select(."display-name"=="fn-keepalive") | select(."lifecycle-state"=="ACTIVE") | .id'| tr -d \"`

export OCI_api_gw_hostname=`oci api-gateway gateway list \
--compartment-id ${TF_VAR_oci_compartment_ocid} --all \
| jq '.data.items[]|select(."display-name"=="fn api gateway")|select(."lifecycle-state"=="ACTIVE")|.hostname'`

export OCI_api_gw_ocid=`oci api-gateway gateway list \
--compartment-id ${TF_VAR_oci_compartment_ocid} --all \
| jq '.data.items[]|select(."display-name"=="fn api gateway")|select(."lifecycle-state"=="ACTIVE")|.id'| tr -d \"`

read -r -d '' SPEC_JSON <<- _EOL_
{
  "routes": [{
    "backend": {
      "functionId": "$OCI_fn_fun_ocid",
      "type": "ORACLE_FUNCTIONS_BACKEND"
    },
    "methods": [
      "GET",
      "HEAD"
    ],
    "path": "/"
  }]
}
_EOL_

echo $SPEC_JSON > tmp.spec.json

oci api-gateway deployment create \
--compartment-id ${TF_VAR_oci_compartment_ocid} \
--gateway-id ${OCI_api_gw_ocid} --path-prefix "/check" --display-name "keepalive check" \
--specification file://tmp.spec.json

rm tmp.spec.json

oci health-checks http-monitor create --compartment-id ${TF_VAR_oci_compartment_ocid} \
--display-name "keepalive-check" --interval-in-seconds 300 \
--targets "[${OCI_api_gw_hostname}]" \
--method HEAD --path "/check/" --protocol "HTTPS" --timeout-in-seconds 30 \
--vantage-point-names ${OCI_vantage_points}

