using System;
using System.Collections.Generic;

using Xamarin.Forms;

namespace RealmTasks
{
    public partial class TasksPage : PageBase
    {
        private readonly Lazy<TasksViewModel> _typedViewModel = new Lazy<TasksViewModel>();

        public override ViewModelBase ViewModel => _typedViewModel.Value;

        public TasksPage()
        {
            InitializeComponent();

            BindingContext = ViewModel;
        }

        private void OnItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var listView = (ListView)sender;
            listView.SelectedItem = null;
        }
    }
}
