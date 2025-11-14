##############################
# 1. Enable JWT/OIDC Auth
##############################
resource "vault_auth_backend" "jwt" {
  type        = "jwt"
  path        = "github"
  description = "GitHub Actions OIDC"
  namespace   = "admin/uuid"
}

##############################
# 2. Configure GitHub OIDC
##############################
resource "vault_jwt_auth_backend_config" "github" {
  backend            = vault_auth_backend.jwt.path
  namespace          = "admin/uuid"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

##############################
# 3. Policy for GitHub Access
##############################
resource "vault_policy" "github_policy" {
  name      = "github-secrets-policy"
  namespace = "admin/uuid"

  policy = <<EOT
path "secret/data/app" {
  capabilities = ["read"]
}
EOT
}

##############################
# 4. GitHub OIDC ROLE
##############################
resource "vault_jwt_auth_backend_role" "github_role" {
  backend   = vault_auth_backend.jwt.path
  role_name = "github-actions-role"
  namespace = "admin/uuid"

  # ALLOW ONLY THIS REPO
  bound_subject = "repo:OWNER/REPO:*"

  token_policies = [
    vault_policy.github_policy.name
  ]

  user_claim = "sub"
  token_ttl  = 3600
}

##############################
# 5. Secret in KV v2
##############################
resource "vault_kv_secret_v2" "app_secret" {
  mount     = "secret"
  name      = "app"
  namespace = "admin/uuid"

  data_json = jsonencode({
    username = "demo-user"
    password = "super-secret-password"
  })
}

##############################
# Variables
##############################
variable "vault_token" {
  type        = string
  description = "Admin token for provisioning Vault"
}
