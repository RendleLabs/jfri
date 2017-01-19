# Configure Docker to listen on TCP sockets as well as Unix socket
mkdir /etc/systemd/system/docker.service.d
mkdir -p /etc/docker/ssl
mv /tmp/server-*.pem /etc/docker/ssl
sudo chown -R root:root /etc/docker/ssl

cat <<! >/etc/systemd/system/docker.service.d/tcp.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd \
  --tls=true --tlscert=/etc/docker/ssl/server-cert.pem --tlskey=/etc/docker/ssl/server-key.pem \
  -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2376
!

# Restart Docker with config changes
systemctl daemon-reload
systemctl restart docker
