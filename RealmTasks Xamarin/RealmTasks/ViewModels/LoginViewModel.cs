using System;
using System.Threading.Tasks;
using System.Windows.Input;
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

        private string _username;
        private string _password;
        private string _serverUrl;

        public string Username
        {
            get
            {
                return _username;
            }

            set
            {
                Set(ref _username, value);
            }
        }

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

        public string ServerUrl
        {
            get
            {
                return _serverUrl;
            }

            set
            {
                Set(ref _serverUrl, value);
            }
        }

        public Command LoginCommand { get; }

        public LoginViewModel()
        {
            LoginCommand = new Command(Login, () => !IsBusy);
        }

        private void Login()
        {
            PerformTask(async () =>
            {
                ServerUrl = ServerUrl.Replace("http://", string.Empty)
                                     .Replace("https://", string.Empty)
                                     .Replace("realm://", string.Empty)
                                     .Replace("realms://", string.Empty);

                Constants.Server.SyncHost = ServerUrl;

                var credentials = Credentials.UsernamePassword(Username, Password, false);
                var user = await User.LoginAsync(credentials, Constants.Server.AuthServerUri);

                Success(user);
            }, onError: ex =>
            {
                // TODO: show alert.

                DialogService.Alert("Unable to login", ex.Message);
                HandleException(ex);
            }, progressMessage: "Logging in...");
        }
    }
}