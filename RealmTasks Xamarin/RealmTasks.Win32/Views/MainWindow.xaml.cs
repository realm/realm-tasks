using System.Windows;

namespace RealmTasks
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            var navigationService = DependencyService.Get<INavigationService>(DependencyFetchTarget.GlobalInstance);
            navigationService.SetMainPage<ListsViewModel>();
        }
    }
}
