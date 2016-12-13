using System;
using System.Linq;
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

        public LoginViewModel()
        {
            LoginCommand = new Command(Login, () => !IsBusy);

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

                var credentials = Credentials.UsernamePassword(Details.Username, Password, false);
                var user = await User.LoginAsync(credentials, Constants.Server.AuthServerUri);

                Success(user);
            }, onError: ex =>
            {
                // TODO: show alert.

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