using System;

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
    }
}
