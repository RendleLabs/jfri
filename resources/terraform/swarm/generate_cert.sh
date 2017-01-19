HOSTNAME=$1
PUBLIC_IP=$2
PRIVATE_IP=$3
CA_PASSPHRASE=$4

rm -f ./docker-config/server-*.pem

openssl genrsa -out ./docker-config/server-key.pem 4096

echo subjectAltName = IP:${PUBLIC_IP},IP:${PRIVATE_IP},IP:127.0.0.1 > extfile.cnf

openssl req -subj "/CN=${HOSTNAME}" -sha256 -new -key ./docker-config/server-key.pem -out ./docker-config/server.csr

openssl x509 -req -days 365 -sha256 \
  -in ./docker-config/server.csr \
  -CA ca.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -out ./docker-config/server-cert.pem \
  -extfile extfile.cnf \
  -passin pass:${CA_PASSPHRASE}

chmod 400 ./docker-config/server-*.pem
