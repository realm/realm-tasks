using System.Windows.Controls;

namespace RealmTasks
{
    public abstract partial class PageBase : Page
    {
        public abstract ViewModelBase ViewModel { get; }

        protected PageBase()
        {
            ViewModel.Initialize();
        }
    }
}
