# Terraform / OpenTofu Project Setup Guide

This document outlines the prerequisites and setup instructions for working with our infrastructure using Terraform (via OpenTofu) and Terragrunt.


## Prerequisites

Ensure the following tools are installed on your machine:

- [gcloud CLI](https://cloud.google.com/sdk/docs/install): Google Cloud SDK for authentication and project access.
- [tofuenv](https://github.com/tofuutils/tofuenv): Version manager for OpenTofu.
- [terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/): Wrapper for Terraform that provides extra tooling for managing infrastructure.
- [pre-commit](https://pre-commit.com/): Tool to manage and maintain multi-language pre-commit hooks.

Inside `deploy/common.hcl` is a Terraform backend. By default it is set to use Google Cloud Storage for remote state. Be sure it is pointing to a bucket in a project you control.

## Setup

1. **Authenticate with Google Cloud**

    This grants Terraform access to GCP using your default credentials. Allows for remote backend.

    ```bash
    $ gcloud auth application-default login
    ```

2. **Set your Bitwarden access token**

    This allows Terragrunt to pull secrets from your Bitwarden vault.

    ```bash
    $ export BWS_ACCESS_TOKEN=<your_bitwarden_access_token>
    ```

3. **Install Git hooks**

    Install the pre-commit hooks to ensure code quality and formatting consistency:

    ```bash
    $ pre-commit install
    ```
4. **Install OpenTofu**

    Install the latest version of OpenTofu and use it:
    ```bash
    $ tofuenv install <version> && tofuenv use <version>
    ```

## Usage

Navigate to the `deploy` directory, then choose the specific service you'd like to apply. For example:

    cd deploy/<service-name>
    terragrunt apply

This will initialize the configuration and apply infrastructure changes for the selected service. Further details can be found in the readme for each service in `deploy/`.
