# Securing server

## Create CA

### Private key
`openssl genrsa -aes256 -out ca-key.pem 4096`

### Public key
`openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem`

## Server key

### Generate key
`openssl genrsa -out server-key.pem 4096`

### Generate CSR
`openssl req -subj "/CN={fqdn}" -sha256 -new -key server-key.pem -out server.csr`

### Sign server certificate
```
echo {public_ip} {private_ip} 127.0.0.1 > serverext.cnf
openssl x509 -req -days 365 -sha256 \
  -in server.csr \
  -CA ca.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -passin pass:{CA_PWD} \
  -out server-cert.pem \
  -extfile serverext.cnf
```

### Add files to Terraform resource

Copy the `server.csr`, `server-cert.pem` and `server-key.pem` files to `docker-config`.

## Client key

### Generate key
`openssl genrsa -out key.pem 4096`

### Generate CSR
`openssl req -subj '/CN=client' -new -key key.pem -out client.csr`

### Sign client key
```bash
echo extendedKeyUsage = clientAuth > extfile.cnf
openssl x509 -req -days 365 -sha256 \
  -in client.csr \
  -CA ca.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -passin pass:{CA_PWD} \
  -out cert.pem \
  -extfile extfile.cnf
```

### Add client certificates to docker

Copy the `key.pem` and `cert.pem` files to `$HOME/.docker`.

Now just set the `DOCKER_TLS_VERIFY` environment variable to `1` to enable secure communication with your remote Docker host.