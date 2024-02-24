variable "env" {
  type    = string
  default = "snb"
}

variable "kube_config_path" {
  type    = string
  default = ".terraform/kube_config.yml"
}
