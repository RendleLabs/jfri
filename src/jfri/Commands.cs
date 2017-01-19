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
        public Command DockerBuild
            => new Command("docker",
                           $"build -t {_config.ImageName} .",
                           $"Building image: {_config.ImageName}");

        public Command DockerTag
            => new Command("docker",
            $"tag {_config.ImageName} {_config.RegistryHost}/{_config.ImageName}",
            $"Applying tag: {_config.RegistryHost}/{_config.ImageName}");

        public Command DockerPush
            => new Command("docker",
            $"push {_config.RegistryHost}/{_config.ImageName}",
            $"Pushing image to {_config.RegistryHost}");

        public Command DockerServiceCreate
            => new Command("docker",
            $"service create --with-registry-auth --name {_config.ServiceName} " +
                   $"--label traefik.port={_config.ContainerPort} " +
                   $"--network {_config.SwarmNetwork} " +
                   $"{_config.RegistryHost}/{_config.ImageName}",
            $"Creating service: {_config.ServiceName}",
            remote: true);
    }

    public class Command
    {
        public Command(string file, string arguments, string output, bool remote = false)
        {
            File = file;
            Arguments = arguments;
            Output = output;
            Remote = remote;
        }

        public string File { get; }
        public string Arguments { get; }
        public string Output { get; }
        public bool Remote { get; set; }
    }
}