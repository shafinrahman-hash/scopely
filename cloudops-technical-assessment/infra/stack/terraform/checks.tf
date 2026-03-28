check "database_secret_mode_inputs" {
  assert {
    condition = var.use_secrets_manager ? (
      var.rds_database_url_secret_arn != null && length(var.rds_database_url_secret_arn) > 0
    ) : (
      var.rds_db_password != null && length(var.rds_db_password) > 0
    )
    error_message = "Set rds_database_url_secret_arn when use_secrets_manager=true, otherwise set rds_db_password (e.g. via TF_VAR_rds_db_password)."
  }
}

check "https_certificate_inputs" {
  assert {
    condition = var.enable_https ? (
      var.acm_certificate_arn != null && length(var.acm_certificate_arn) > 0
    ) : true
    error_message = "When enable_https is true, acm_certificate_arn must be provided."
  }
}
