using System;
using System.IO;

namespace Jfri
{
    public class Dockerfile
    {
        public void Create()
        {
            var path = Path.Combine(System.IO.Directory.GetCurrentDirectory(), "Dockerfile");
            if (!File.Exists(path))
            {
                using (var writer = File.CreateText(path))
                {
                    writer.Write(Text);
                }
            }
        }

        private const string Text = @"FROM rendlelabs/dotnet:latest

COPY . /app

WORKDIR /app

RUN [""dotnet"", ""restore""]

RUN [""dotnet"", ""build""]

EXPOSE 5000/tcp

CMD [""dotnet"", ""run"", ""--server.urls"", ""http://*:5000""]
";
    }
}