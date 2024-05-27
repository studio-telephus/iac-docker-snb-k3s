locals {
  cluster_domain = "cluster.local"
  nicparent      = "${var.env}-docker"
  containers_server = [
    {
      name         = "container-${var.env}-k3s-s1"
      ipv4_address = "10.90.0.11"
    }
  ]
  containers_worker     = []
  fixed_registration_ip = "10.90.0.31"
  workload_ip           = "10.90.0.32"
}

module "container_loadbalancer_slb" {
  source = "github.com/studio-telephus/terraform-docker-haproxy.git?ref=main"
  image  = data.docker_image.debian_bookworm.id
  name   = "container-${var.env}-k3s-slb"
  networks_advanced = [
    {
      name         = local.nicparent
      ipv4_address = local.fixed_registration_ip
    }
  ]
  bind_port = 6443
  servers = [for item in local.containers_server : {
    address : item.ipv4_address,
    port : 6443
  }]
  stats_auth_password = module.bw_haproxy_stats.data.password
}

module "container_loadbalancer_alb" {
  source = "github.com/studio-telephus/terraform-docker-haproxy.git?ref=main"
  image  = data.docker_image.debian_bookworm.id
  name   = "container-${var.env}-k3s-alb"
  networks_advanced = [
    {
      name         = local.nicparent
      ipv4_address = local.workload_ip
    }
  ]
  bind_port = 443
  servers = [for item in local.containers_server : {
    address : item.ipv4_address,
    port : 443
  }]
  stats_auth_password = module.bw_haproxy_stats.data.password
}

resource "docker_volume" "k3s_longhorn" {
  name = "volume-${var.env}-k3s-longhorn"
}

# Mimics https://github.com/rancher/k3s/blob/master/docker-compose.yml
resource "docker_volume" "k3s_server" {
  name = "volume-${var.env}-k3s-server"
}

module "docker_k3s_swarm" {
  source            = "github.com/studio-telephus/terraform-docker-k3s-swarm.git?ref=main"
  swarm_private_key = module.bw_swarm_private_key.data.notes
  containers        = concat(local.containers_server, local.containers_worker)
  network_name      = local.nicparent
  restart           = "unless-stopped"
  mounts = [
    {
      target = "/run"
      type   = "tmpfs"
    },
    {
      target = "/var/run"
      type   = "tmpfs"
    },
    {
      target = "/var/lib/rancher/k3s"
      source = docker_volume.k3s_server.name
      type   = "volume"
    },
    {
      target = "/var/lib/longhorn"
      source = docker_volume.k3s_longhorn.mountpoint
      type   = "bind"
      bind_options = {
        propagation = "rshared"
      }
    }
  ]
  volumes = [
    {
      container_path = "/sys/fs/cgroup"
      host_path      = "/sys/fs/cgroup"
      read_only      = false
    },
    {
      container_path = "/lib/modules"
      host_path      = "/lib/modules"
      read_only      = false
    }
  ]
  depends_on = [
    docker_volume.k3s_server,
    docker_volume.k3s_longhorn
  ]
}

module "k3s_cluster_embedded" {
  source          = "github.com/studio-telephus/terraform-k3s-cluster-embedded.git?ref=main"
  ssh_private_key = module.bw_swarm_private_key.data.notes
  cluster_domain  = local.cluster_domain
  cidr_pods       = "10.90.10.0/22"
  cidr_services   = "10.90.15.0/22"
  k3s_install_env_vars = {
    "K3S_KUBECONFIG_MODE" = "644"
  }
  server_flags = [
    "--disable local-storage",
    "--tls-san ${local.fixed_registration_ip}"
  ]
  containers_server = local.containers_server
  containers_worker = local.containers_worker
  depends_on = [
    module.docker_k3s_swarm,
    module.container_loadbalancer_slb
  ]
}

resource "local_sensitive_file" "kube_config" {
  content    = module.k3s_cluster_embedded.k3s_kube_config
  filename   = var.kube_config_path
  depends_on = [module.k3s_cluster_embedded]
}

resource "bitwarden_item_secure_note" "k3s_credentials" {
  name = "platform_k3s_${var.env}_root_credentials"
  field {
    name = "host_int"
    text = "https://${local.fixed_registration_ip}:6443"
  }
  field {
    name = "host_ext"
    text = "https://telephus.k-space.ee:49639"
  }
  field {
    name = "client_certificate"
    text = base64encode(module.k3s_cluster_embedded.k3s_kubernetes.client_certificate)
  }
  field {
    name = "client_key"
    text = base64encode(module.k3s_cluster_embedded.k3s_kubernetes.client_key)
  }
  field {
    name = "cluster_ca_certificate"
    text = base64encode(module.k3s_cluster_embedded.k3s_kubernetes.cluster_ca_certificate)
  }
}
