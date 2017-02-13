using Android.App;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using RealmTasks.Droid;
using Xamarin.Forms;

[assembly: Dependency(typeof(ADAuthenticator))]

namespace RealmTasks.Droid
{
    public class ADAuthenticator : IADAuthenticator
    {
        public IPlatformParameters GetPlatformParameters()
        {
            var activity = (Activity)Forms.Context;
            return new PlatformParameters(activity);
        }
    }
}
