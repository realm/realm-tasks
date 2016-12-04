using System;
using Xamarin.Forms;

namespace RealmTasks
{
    public partial class ListsPage : PageBase
    {
        private readonly Lazy<ListsViewModel> _typedViewModel = new Lazy<ListsViewModel>();
        public override ViewModelBase ViewModel => _typedViewModel.Value;

        public ListsPage()
        {
            InitializeComponent();

            BindingContext = ViewModel;
        }
    }
}