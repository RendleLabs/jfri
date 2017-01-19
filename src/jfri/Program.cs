using System;
using System.Diagnostics;
using Microsoft.Extensions.Configuration;

namespace Jfri
{
    public class Program
    {
        static void Main(string[] args)
        {
            new Dockerfile().Create();

            var config = new Config();
            new ConfigurationBuilder()
                .SetBasePath(System.IO.Directory.GetCurrentDirectory())
                .AddJsonFile("jfri.json", optional: true)
                .AddEnvironmentVariables("JFRI_")
                .AddCommandLine(args)
                .Build()
                .Bind(config);
            
            Convention.Apply(config);
            
            var commands = new Commands(config);
            var run = new Run(config);

            run.Do(commands.DockerBuild);
            run.Do(commands.DockerTag);
            run.Do(commands.DockerPush);
            run.Do(commands.DockerServiceCreate);
        }
    }
}