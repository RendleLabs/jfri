using System;
using Microsoft.Extensions.Configuration;

namespace Jfri
{
    public class Program
    {
        static void Main(string[] args)
        {
            var config = new Config();
            new ConfigurationBuilder()
                .SetBasePath(System.IO.Directory.GetCurrentDirectory())
                .AddJsonFile("jfri.json", optional: true)
                .AddEnvironmentVariables("JFRI_")
                .AddCommandLine(args)
                .Build()
                .Bind(config);
            
            var commands = new Commands(config);

            System.Console.WriteLine(commands.DockerBuild);
            System.Console.WriteLine(commands.DockerTag);
            System.Console.WriteLine(commands.DockerPush);
            System.Console.WriteLine(commands.DockerServiceCreate);
        }
    }
}