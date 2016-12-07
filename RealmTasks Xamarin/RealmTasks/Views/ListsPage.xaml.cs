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

        private void TitleEntryCompleted(object sender, EventArgs e)
        {
            var taskList = ((Entry)sender).BindingContext as TaskList;
            if (taskList != null)
            {
                taskList.IsEditing = false;
            }
        }

        private void OnItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var listView = (ListView)sender;
            listView.SelectedItem = null;
        }
    }
}