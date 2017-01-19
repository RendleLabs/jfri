using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Configuration;

namespace Jfri
{
    public class Convention
    {
        public static Config Apply(Config config)
        {
            if (string.IsNullOrWhiteSpace(config.ServiceName))
            {
                config.ServiceName = Sanitize(Path.GetFileNameWithoutExtension(Directory.GetCurrentDirectory()));
            }

            if (string.IsNullOrWhiteSpace(config.ImageName))
            {
                config.ImageName = $"jfri-{config.ServiceName}";
            }

            if (string.IsNullOrWhiteSpace(config.SwarmDockerHost))
            {
                config.SwarmDockerHost = Environment.GetEnvironmentVariable("DOCKER_HOST");
            }

            if (string.IsNullOrWhiteSpace(config.RegistryHost))
            {
                config.RegistryHost = GetRegistryHostFromDockerConfig();
            }

            if (string.IsNullOrWhiteSpace(config.SwarmNetwork))
            {
                config.SwarmNetwork = "traefik";
            }

            if (config.ContainerPort == 0)
            {
                config.ContainerPort = 5000;
            }

            return config;
        }

        private static string Sanitize(string source)
        {
            return Regex.Replace(source, "[^a-z0-9_-]+", "-", RegexOptions.IgnoreCase);
        }

        private static string GetDockerHostFromEnvironment()
        {
            var value = Environment.GetEnvironmentVariable("DOCKER_HOST");
            if (string.IsNullOrWhiteSpace(value))
            {
                throw new InvalidOperationException("No DOCKER_HOST configured.");
            }
            return GetHostName(value);
        }

        private static string GetHostName(string url)
        {
            var withoutScheme = Regex.Replace(url, @"^tcp:\/\/", "");
            var withoutPort = Regex.Replace(withoutScheme, @":[0-9]+$", "");
            return withoutPort;
        }

        private static string GetRegistryHostFromDockerConfig()
        {
            var homeDirectory = Environment.GetEnvironmentVariable("HOME") ?? Environment.GetEnvironmentVariable("HOMEPATH");
            if (string.IsNullOrWhiteSpace(homeDirectory))
            {
                return null;
            }

            var dotDocker = Path.Combine(homeDirectory, ".docker");

            if (Directory.Exists(dotDocker))
            {
                var configPath = Path.Combine(dotDocker, "config.json");
                if (File.Exists(configPath))
                {
                    var config = new ConfigurationBuilder()
                        .AddJsonFile(configPath)
                        .Build();
                    
                    var auths = config.GetSection("auths");
                    if (auths != null)
                    {
                        foreach (var pair in auths.GetChildren().AsEnumerable())
                        {
                            System.Console.WriteLine(pair.Key);
                        }
                        var pairs = auths.GetChildren().AsEnumerable()
                            .Where(kvp => !(kvp.Key.Contains("docker.io") || kvp.Key.Contains(":") || kvp.Key.StartsWith("http")))
                            .ToArray();
                        if (pairs.Length == 1)
                        {
                            return GetHostName(pairs[0].Key);
                        }
                    }
                }
            }

            return null;
        }
    }
}