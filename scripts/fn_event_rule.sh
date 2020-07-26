#!/bin/bash

export OCI_fn_fun_ocid=`oci fn function list \
--application-id $OCI_auto_app_ocid \
| jq '.data[] | select(."display-name"=="event-create-thumb") | .id'| tr -d \"`

read -r -d '' ACTIONS_JSON <<- _EOL_
{
    "actions": [
        {
            "actionType": "FAAS",
            "description": "process in fn",
            "functionId": "${OCI_fn_fun_ocid}",
            "isEnabled": true
        }
    ]
}
_EOL_

echo $ACTIONS_JSON > actions.json

oci events rule create --compartment-id $TF_VAR_oci_compartment_ocid \
--display-name "process_images" \
--condition "{\"eventType\":[\"com.oraclecloud.objectstorage.createobject\",\
\"com.oraclecloud.objectstorage.updateobject\",\
\"com.oraclecloud.objectstorage.deleteobject\"],\
\"data\":{\
\"resourceName\":[\"*.jpg\",\"*.JPG\",\"*.png\",\"*.PNG\",\"*.gif\",\"*.GIF\"],\
\"additionalDetails\":{\"bucketName\":[\"${OCI_storage_bucket}\"]}\
}}" \
--actions file://actions.json --is-enabled true



