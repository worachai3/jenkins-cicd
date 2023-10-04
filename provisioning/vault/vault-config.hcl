listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = 1
}

storage "file" {
    path = "/vault/data"
}

disable_mlock = true
api_addr = "http://localhost:8200"
cluster_addr = "https://localhost:8201"
ui = true