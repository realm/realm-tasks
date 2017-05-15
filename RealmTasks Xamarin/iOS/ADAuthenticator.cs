using Microsoft.IdentityModel.Clients.ActiveDirectory;
using RealmTasks.iOS;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(ADAuthenticator))]

namespace RealmTasks.iOS
{
    public class ADAuthenticator : IADAuthenticator
    {
        public IPlatformParameters GetPlatformParameters()
        {
            return new PlatformParameters(GetTopMostController());
        }

        private UIViewController GetTopMostController()
        {
            var topMost = UIApplication.SharedApplication.KeyWindow.RootViewController;

            while (topMost.PresentedViewController != null)
            {
                topMost = topMost.PresentedViewController;
            }

            return topMost;
        }
    }
}
