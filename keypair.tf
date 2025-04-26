#Resource to create a SSH private key
resource "tls_private_key" "P1_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


#Resource to Create Key Pair
resource "aws_key_pair" "P1_3tier_archi_keypair" {
  key_name   = "P1 3tier archi keypair"
  public_key = tls_private_key.P1_keypair.public_key_openssh
}

resource "local_file" "P1_3tier_archi_keypair_private" {
  filename        = "P1_3tier_archi_keypair_private"
  file_permission = "0400"
  content         = tls_private_key.P1_keypair.private_key_pem
}

