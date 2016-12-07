using Xamarin.Forms;

namespace RealmTasks
{
    public abstract class PageBase : ContentPage
    {
        public abstract ViewModelBase ViewModel { get; }

        protected PageBase()
        {
            SetBinding(TitleProperty, new Binding("Title"));
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            ViewModel.Initialize();
        }
    }
}