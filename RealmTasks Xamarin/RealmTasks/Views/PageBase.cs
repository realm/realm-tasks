using Xamarin.Forms;

namespace RealmTasks
{
    public abstract class PageBase : ContentPage
    {
        public abstract ViewModelBase ViewModel { get; }

        protected PageBase()
        {
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            ViewModel.OnAppearing();
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();
        }
    }
}