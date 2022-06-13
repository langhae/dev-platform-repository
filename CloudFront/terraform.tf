################################################################################
# Backend terraform Cloud
################################################################################

terraform {
  backend "remote" {
    organization = "langhae"

    workspaces {
      name = "cloud-front"
    }
  }
}