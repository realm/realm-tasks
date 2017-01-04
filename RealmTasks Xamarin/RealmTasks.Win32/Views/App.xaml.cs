using System.Windows;
using RealmTasks.Implementation;

namespace RealmTasks
{
    public partial class App : Application
    {
        static App()
        {
            DependencyService.Register<INavigationService>(new NavigationService());
            DependencyService.Register<IDialogService>(new DialogService());
        }
    }
}
