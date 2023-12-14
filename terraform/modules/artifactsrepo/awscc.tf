resource "awscc_codeartifact_repository" "evmosd-binaries" {
  domain_name     = "evmos"
  repository_name = "evmosd_binaries"
}
