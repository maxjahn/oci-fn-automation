
output "os_namespace" {
  value = [data.oci_objectstorage_namespace.os_ns.namespace]
}

output "automation_app_ocid" {
  value = [oci_functions_application.automation_app.id]
}

output "auto_user_ocid" {
  value = [oci_identity_user.auto_user.id]
}

resource "local_file" "conn_string_file" {
  content  = "#!/bin/bash\nexport OCI_storage_tenancy=${data.oci_objectstorage_namespace.os_ns.namespace}\nexport OCI_storage_bucket=${oci_objectstorage_bucket.img_bucket.name}\nexport OCI_automation_user_ocid=${oci_identity_user.auto_user.id}\nexport OCI_automation_user=${oci_identity_user.auto_user.name}\nexport OCI_auto_app_ocid=${oci_functions_application.automation_app.id} "
  filename = "../scripts/oci_env.sh"
}

