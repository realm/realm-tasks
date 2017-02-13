using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Realms;
using Realms.Sync;
using Xamarin.Forms;

namespace RealmTasks
{
    public class LoginViewModel : ViewModelBase, IPromptable<User>
    {
        #region Promptable

        public Action<User> Success { get; set; }

        public Action Cancel { get; set; }

        public Action<Exception> Error { get; set; }

        #endregion

        private readonly Realm _realm;
        private readonly Lazy<IADAuthenticator> _adAuthenticator = new Lazy<IADAuthenticator>(() => DependencyService.Get<IADAuthenticator>());
        private string _password;

        public LoginDetails Details { get; }

        public string Password
        {
            get
            {
                return _password;
            }

            set
            {
                Set(ref _password, value);
            }
        }

        public Command LoginCommand { get; }
        public Command LoginWithADCommand { get; }

        public LoginViewModel()
        {
            LoginCommand = new Command(Login, () => !IsBusy);
            LoginWithADCommand = new Command(LoginWithAD, () => !IsBusy);

            var cacheConfig = new RealmConfiguration("logincache.realm")
            {
                ObjectClasses = new[] { typeof(LoginDetails) }
            };

            _realm = Realm.GetInstance(cacheConfig);
            var loginDetails = _realm.All<LoginDetails>().FirstOrDefault();
            if (loginDetails == null)
            {
                loginDetails = new LoginDetails
                {
                    ServerUrl = Constants.Server.SyncHost
                };

                _realm.Write(() => _realm.Add(loginDetails));
            }

            Details = loginDetails;
        }

        private void Login()
        {
            LoginCore(() => System.Threading.Tasks.Task.FromResult(Credentials.UsernamePassword(Details.Username, Password, false)));
        }

        private void LoginWithAD()
        {
            LoginCore(async () =>
            {
                var authContext = new AuthenticationContext(Constants.ADCredentials.CommonAuthority);

                var clientId = Constants.ADCredentials.ClientId;
                var redirectUri = Constants.ADCredentials.RedirectUri;
                if (clientId == "your-client-id" || redirectUri.AbsolutePath == "http://your-redirect-uri")
                {
                    throw new Exception("Please update Constants.ADCredentials with the correct ClientId and RedirectUri for your application.");
                }

                var response = await authContext.AcquireTokenAsync("https://graph.windows.net",
                                                                   clientId,
                                                                   redirectUri,
                                                                   _adAuthenticator.Value.GetPlatformParameters());

                // TODO: uncomment when implemented
                // var credentials = Credentials.ActiveDirectory(response.AccessToken);
                return Credentials.Debug();
            });
        }

        private void LoginCore(Func<Task<Credentials>> getCredentialsFunc)
        {
            PerformTask(async () =>
            {
                _realm.Write(() =>
                {
                    Details.ServerUrl = Details.ServerUrl.Replace("http://", string.Empty)
                                                         .Replace("https://", string.Empty)
                                                         .Replace("realm://", string.Empty)
                                                         .Replace("realms://", string.Empty);
                });

                Constants.Server.SyncHost = Details.ServerUrl;

                var credentials = await getCredentialsFunc();
                var user = await User.LoginAsync(credentials, Constants.Server.AuthServerUri);

                Success(user);
            }, onError: ex =>
            {
                DialogService.Alert("Unable to login", ex.Message);
                HandleException(ex);
            }, progressMessage: "Logging in...");
        }

        public class LoginDetails : RealmObject
        {
            public string ServerUrl { get; set; }

            public string Username { get; set; }
        }
    }
}