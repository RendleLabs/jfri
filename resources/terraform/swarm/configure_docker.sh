# Configure Docker to listen on TCP sockets as well as Unix socket
mkdir /etc/systemd/system/docker.service.d

cat <<! >/etc/systemd/system/docker.service.d/tcp.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375
!

# Restart Docker with config changes
systemctl daemon-reload
systemctl restart docker
