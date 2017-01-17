using System;
using System.IO;
using System.Text.RegularExpressions;

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

            return config;
        }

        private static string Sanitize(string source)
        {
            return source;
        }
    }
}