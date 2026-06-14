# Google Cloud Storage as the remote state backend

Terraform/OpenTofu state is stored remotely in a Google Cloud Storage bucket,
configured once in `deploy/common.hcl` and generated into each unit's backend
via Terragrunt (`prefix = path_relative_to_include()`), so every LXC Domain and
service gets an isolated state path under one bucket.

Remote state is required for safe, shared, locked state rather than local files
on one workstation. GCS was chosen as the backend; operators authenticate with
`gcloud auth application-default login`. The lock-in is a dependency on GCP for
state storage and the requirement that the configured bucket exists in a project
the operator controls.
