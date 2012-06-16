using System;

namespace SupportPortal.Utility
{
    public interface IRoleEnvironment
    {
        bool IsAzureAvailable { get; }
        string GetConfigurationValue(string name);
        string GetResourceLocation(string resourceName);
    }

    public class RoleEnvironment : IRoleEnvironment
    {
        public bool IsAzureAvailable
        {
            get { return Environment.GetEnvironmentVariable("INAZURE", EnvironmentVariableTarget.Machine) != null; }
        }

        public string GetConfigurationValue(string name)
        {
            return Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment.GetConfigurationSettingValue(name);
        }

        public string GetResourceLocation(string resourceName)
        {
            return Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment.GetLocalResource(resourceName).RootPath;
        }
    }
}