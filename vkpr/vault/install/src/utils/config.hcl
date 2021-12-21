ui = true

listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}

service_registration "kubernetes" {}
