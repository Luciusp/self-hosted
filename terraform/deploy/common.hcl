remote_state {
    backend = "gcs"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
    config = {
        prefix = "${path_relative_to_include()}"
        bucket = "terraform-state-e9405433-c350-4e9f-b5f3-edb2c2323fd4"
    }
}
