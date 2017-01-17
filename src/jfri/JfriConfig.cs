using System;
using System.IO;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace Jfri
{
    public class JfriConfig
    {
        public string ServiceName { get; set; }
    }

    public class LoadConfig
    {
        public static JfriConfig FromFile(string filename)
        {
            return FromString(ReadFileAsString(filename));
        }

        public static JfriConfig FromString(string yaml)
        {
            var deserializer = new DeserializerBuilder().WithNamingConvention(new CamelCaseNamingConvention()).Build();
            return deserializer.Deserialize<JfriConfig>(yaml);
        }

        private static string ReadFileAsString(string filename)
        {
            using (var stream = File.OpenRead(filename))
            using (var reader = new StreamReader(stream))
            {
                return reader.ReadToEnd();
            }
        }
    }
}