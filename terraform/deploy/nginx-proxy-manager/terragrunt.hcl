locals {
  domains = jsondecode(read_tfvars_file("secrets.tfvars"))
}

include {
  path = find_in_parent_folders("common.hcl")
}

dependency "bitwarden" {
  config_path = "${get_terragrunt_dir()}/../bitwarden-secrets"
}

terraform {
  source = find_in_parent_folders("modules/nginx-proxy-manager")
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
    required_providers {
        nginxproxymanager = {
            source = "Sander0542/nginxproxymanager"
            version = "1.1.0"
        }
    }
}

provider "nginxproxymanager" {
    url         = "${dependency.bitwarden.outputs.secrets["nginxproxymanager_url"].value}"
    username    = "${dependency.bitwarden.outputs.secrets["nginxproxymanager_email"].value}"
    password    = "${dependency.bitwarden.outputs.secrets["nginxproxymanager_password"].value}"
}
EOF
}

inputs = {
  ssl_certificates = {
    "hf" = {
      domain_names            = ["*.${local.domains.hf_domain}"]
      letsencrypt_email       = dependency.bitwarden.outputs.secrets["nginxproxymanager_email"].value
      dns_provider            = "cloudflare"
      dns_provider_credential = dependency.bitwarden.outputs.secrets["cloudflare_api_token"].value
      credential_prefix       = "dns_cloudflare_api_token="
    }
  }

  service_proxies = {
    "admin" = {
      domain_names     = ["admin.${local.domains.hf_domain}"]
      ip               = "192.168.0.216",
      port             = 81,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "assistant" = {
      domain_names     = ["assistant.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 8123,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "audiobookshelf" = {
      domain_names = ["abs.${local.domains.hf_domain}"]
      ip           = "192.168.0.3",
      port         = 13378,
      scheme       = "http"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    }
    "auth" = {
      domain_names = ["auth.${local.domains.hf_domain}"]
      ip           = "192.168.0.3",
      port         = 9443,
      scheme       = "https"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "bazarr" = {
      domain_names     = ["bazarr.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 6767,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "copyparty" = {
      domain_names = ["copy.${local.domains.hf_domain}"]
      ip           = "192.168.0.3",
      port         = 3923,
      scheme       = "http"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "hedgedoc" = {
      domain_names = ["hedgedoc.${local.domains.hf_domain}"]
      ip           = "192.168.0.3",
      port         = 3000,
      scheme       = "http"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "hoth" = {
      domain_names     = ["hoth.${local.domains.hf_domain}"]
      ip               = "192.168.0.200",
      port             = 8006,
      scheme           = "https"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "kamino" = {
      domain_names     = ["kamino.${local.domains.hf_domain}"]
      ip               = "192.168.0.2",
      port             = 8006,
      scheme           = "https"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "overseerr" = {
      domain_names = ["overseerr.${local.domains.hf_domain}"]
      ip           = "192.168.0.3",
      port         = 5055,
      scheme       = "http"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "paperless" = {
      domain_names = ["paperless.${local.domains.hf_domain}"]
      ip           = "192.168.0.3",
      port         = 8000,
      scheme       = "http"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "pi" = {
      domain_names     = ["pi.${local.domains.hf_domain}"]
      ip               = "192.168.0.216",
      port             = 7989,
      scheme           = "http"
      access_list_name = "LAN"
      custom_locations = {
        "rewrite" : {
          forward_hostname_or_ip = "192.168.0.216"
          forward_port           = 7989
          forward_scheme         = "http"
          location               = "/"
          advanced_config        = "rewrite ^/$ /admin break;"
        }
      }

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "prowlarr" = {
      domain_names     = ["prowlarr.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 9696,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "radarr" = {
      domain_names     = ["radarr.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 7878,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "router" = {
      domain_names     = ["router.${local.domains.hf_domain}"]
      ip               = "192.168.0.1",
      port             = 80,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "sab" = {
      domain_names     = ["sab.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 8080,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        force_ssl        = false
        http2_support    = false
        hsts_enabled     = false
        hsts_subdomains  = false
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "sonarr-anime" = {
      domain_names     = ["sonarr-anime.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 8988,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "sonarr" = {
      domain_names     = ["sonarr.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 8989,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "transmission" = {
      domain_names     = ["transmission.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 9091,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    },
    "wiki" = {
      domain_names     = ["wiki.${local.domains.hf_domain}"]
      ip               = "192.168.0.3",
      port             = 80,
      scheme           = "http"
      access_list_name = "LAN"

      ssl = {
        certificate_name = "*.${local.domains.hf_domain}"
      }
    }
  }


  access_lists = {
    "LAN" = {
      name = "LAN"
      access = [
        {
          directive = "allow"
          address   = "192.168.0.0/12"
        }
      ]
      pass_auth   = true
      satisfy_any = true
    }
  }
}
