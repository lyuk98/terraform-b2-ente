terraform {
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    region                      = "us-west-002"

    use_path_style = true
    key            = "terraform-b2-ente.tfstate"
  }
}

# Get account information
data "b2_account_info" "account" {}

# Add random suffix to bucket name
resource "random_bytes" "bucket_suffix" {
  length = 4
}

# Add bucket for photo storage
resource "b2_bucket" "ente" {
  bucket_name = sensitive("ente-${random_bytes.bucket_suffix.hex}")
  bucket_type = "allPrivate"

  cors_rules {
    allowed_operations = [
      "s3_get",
      "s3_head",
      "s3_post",
      "s3_put",
      "s3_delete"
    ]
    allowed_origins = ["*"]
    cors_rule_name  = "ente-cors-rule"
    max_age_seconds = 3000
    allowed_headers = ["*"]
    expose_headers  = ["Etag"]
  }
}

# Create application key for accessing the bucket
resource "b2_application_key" "ente" {
  capabilities = [
    "bypassGovernance",
    "deleteFiles",
    "listFiles",
    "readFiles",
    "shareFiles",
    "writeFileLegalHolds",
    "writeFileRetentions",
    "writeFiles"
  ]
  key_name  = "ente"
  bucket_id = b2_bucket.ente.bucket_id
}

# Write application key to Vault
resource "vault_kv_secret" "application_key" {
  path = "kv/ente/b2/ente-b2"
  data_json = jsonencode({
    key      = b2_application_key.ente.application_key_id
    secret   = b2_application_key.ente.application_key
    endpoint = data.b2_account_info.account.s3_api_url
    region   = "us-west-002"
    bucket   = b2_bucket.ente.bucket_name
  })
}

# Prepare Vault policy document
data "vault_policy_document" "ente_b2" {
  rule {
    path         = vault_kv_secret.application_key.path
    capabilities = ["read"]
    description  = "Allow read-only access to B2 application key"
  }
}

# Create Vault policy for accessing B2 application keys
resource "vault_policy" "ente_b2" {
  name   = "ente-b2"
  policy = data.vault_policy_document.ente_b2.hcl
}
