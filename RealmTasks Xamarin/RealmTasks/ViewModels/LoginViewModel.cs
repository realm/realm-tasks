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

        public ICommand LoginCommand { get; }

        public LoginViewModel()
        {
            LoginCommand = new Command(this.Login);
        }

        private void Login()
        {
            try
            {
                var user = Task.Run(async () =>
                {
                    var credentials = Credentials.UsernamePassword(Username, Password, false);
                    return await User.LoginAsync(credentials, Constants.Server.AuthServerUri);
                }).Result;

                Success(user);
            }
            catch (Exception ex)
            {
                Error(ex);
            }
        }
    }
}