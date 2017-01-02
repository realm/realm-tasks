using RealmTasks.Implementation;
using Xamarin.Forms;

namespace RealmTasks
{
    public partial class App : Application
    {
        public App()
        {
            InitializeComponent();

            var navigationService = DependencyService.Get<INavigationService>(DependencyFetchTarget.GlobalInstance);
            navigationService.SetMainPage<ListsViewModel>();

            Resources = new ResourceDictionary
            {
                ["ListColors"] = Constants.Colors.ListColors,
                ["TaskColors"] = Constants.Colors.TaskColors,
                ["CompletedColor"] = Constants.Colors.CompletedColor,
                ["InverseBooleanConverter"] = new InverseBooleanConverter(),
                ["TaskListToAlphaConverter"] = new TaskListToAlphaConverter()
            };
        }
    }
}
