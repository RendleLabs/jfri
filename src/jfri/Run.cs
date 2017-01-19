using System;
using System.Diagnostics;
using System.IO;

namespace Jfri
{
    public class Run
    {
        private readonly Config _config;
        public Run(Config config)
        {
            _config = config;
        }

        public void Do(Command command)
        {
            System.Console.WriteLine(command.Output);
            var psi = new ProcessStartInfo();
            if (command.Remote)
            {
                psi.Environment["DOCKER_HOST"] = _config.SwarmDockerHost;
                psi.Environment["DOCKER_TLS_VERIFY"] = "1";
            }
            psi.FileName = command.File;
            psi.Arguments = command.Arguments;
            Process.Start(psi).WaitForExit();
        }
    }
}