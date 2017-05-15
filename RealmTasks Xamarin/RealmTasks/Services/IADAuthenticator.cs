using Microsoft.IdentityModel.Clients.ActiveDirectory;

namespace RealmTasks
{
    public interface IADAuthenticator
    {
        IPlatformParameters GetPlatformParameters();
    }
}
