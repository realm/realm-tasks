using System;

namespace RealmTasks
{
    public partial class LoginPage : PageBase
    {
        private readonly Lazy<LoginViewModel> _typedViewModel = new Lazy<LoginViewModel>();

        public override ViewModelBase ViewModel => _typedViewModel.Value;

        public LoginPage()
        {
            InitializeComponent();

            BindingContext = ViewModel;
        }
    }
}
