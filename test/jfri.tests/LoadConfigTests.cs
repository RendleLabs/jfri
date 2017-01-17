using System;
using Xunit;

namespace Jfri.Tests
{
    public class LoadConfigTests
    {
        [Fact]
        public void SetsServiceName()
        {
            const string yaml = @"serviceName: 'guide'";
            var actual = LoadConfig.FromString(yaml);
            Assert.Equal("guide", actual.ServiceName);
        }
    }
}