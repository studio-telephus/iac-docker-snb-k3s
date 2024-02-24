provider "docker" {
  alias = "docker-host"
  host  = "unix:///var/run/docker.sock"
}
