module "bw_swarm_private_key" {
  source = "github.com/studio-telephus/terraform-bitwarden-get-item-secure-note.git?ref=1.0.0"
  id     = "55d048c5-08c2-4319-8503-b0fc00d43adc"
}

module "bw_haproxy_stats" {
  source = "github.com/studio-telephus/terraform-bitwarden-get-item-login.git?ref=1.0.0"
  id     = "a5e768c1-5f50-4af2-bbdc-b0fc00d56ae4"
}
