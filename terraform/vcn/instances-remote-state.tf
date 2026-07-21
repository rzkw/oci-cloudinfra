data "terraform_remote_state" "instances" {
  count = var.instance_ocids != null ? 0 : 1

  backend = "oci"

  config = {
    bucket    = "tfstate"
    namespace = "axvczntoncvg"
    key       = "terraform/instances/terraform.tfstate"
    region    = "ap-melbourne-1"
  }
}
