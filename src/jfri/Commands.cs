using System;
using System.IO;

namespace Jfri
{
    public class Commands
    {
        private readonly Config _config;
        public Commands(Config config)
        {
            this._config = config;

        }
        public string DockerBuild => $"docker build -t {_config.ImageName} .";

        public string DockerTag
            => $"docker tag {_config.ImageName} {_config.RegistryHost}/{_config.ImageName}";

        public string DockerPush
            => $"docker push {_config.RegistryHost}/{_config.ImageName}";

        public string DockerServiceCreate
            => $"docker service create --name {_config.ServiceName} " +
                   $"--label traefik.port={_config.ContainerPort} " +
                   $"--network {_config.SwarmNetwork} " +
                   $"{_config.RegistryHost}/{_config.ImageName}";
    }
}