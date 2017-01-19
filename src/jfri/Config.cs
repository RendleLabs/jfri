using System;
using System.IO;

namespace Jfri
{
    public class Config
    {
        public string ServiceName { get; set; }
        public string ImageName { get; set; }
        public string RegistryHost { get; set; }
        public string SwarmDockerHost { get; set; }
        public string SwarmNetwork { get; set; }
        public int ContainerPort { get; set; }
    }
}