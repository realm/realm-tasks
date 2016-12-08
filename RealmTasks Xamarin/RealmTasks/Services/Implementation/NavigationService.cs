using System;
using System.Threading.Tasks;
using RealmTasks.Implementation;
using Xamarin.Forms;

using ThreadingTask = System.Threading.Tasks.Task;

[assembly: Dependency(typeof(NavigationService))]
namespace RealmTasks.Implementation
{
    public class NavigationService : INavigationService
    {
        private static INavigation Navigation
        {
            get
            {
                return Application.Current.MainPage?.Navigation;
            }
        }

        public ThreadingTask GoBack()
        {
            if (Navigation == null)
            {
                throw new NotSupportedException("Set navigatable main page before calling this.");
            }

            return Navigation.PopAsync(true);
        }

        public ThreadingTask Navigate<T>(Action<T> setup = null) where T : ViewModelBase
        {
            if (Navigation == null)
            {
                throw new NotSupportedException("Set navigatable main page before calling this.");
            }

            var page = GetPage<T>();
            setup?.Invoke((T)page.ViewModel);
            return Navigation.PushAsync(page, true);
        }

        public void SetMainPage<T>() where T : ViewModelBase
        {
            var page = (Page)GetPage<T>();
            Application.Current.MainPage = WrapInNavigation(page);
        }

        public async Task<TResult> Prompt<TViewModel, TResult>() where TViewModel : ViewModelBase, IPromptable<TResult>
        {
            if (Navigation == null)
            {
                throw new NotSupportedException("Set navigatable main page before calling this.");
            }

            var page = GetPage<TViewModel>();
            var promptable = (TViewModel)page.ViewModel;
            var tcs = new TaskCompletionSource<TResult>();
            promptable.Success = tcs.SetResult;
            promptable.Cancel = tcs.SetCanceled;
            promptable.Error = tcs.SetException;

            await Navigation.PushModalAsync(WrapInNavigation(page), true);

            try
            {
                return await tcs.Task;
            }
            finally
            {
                await Navigation.PopModalAsync();
            }
        }

        private static PageBase GetPage<T>()
        {
            var pageType = typeof(T).Name.Replace("ViewModel", "Page");
            return (PageBase)Activator.CreateInstance(Type.GetType($"RealmTasks.{pageType}"));
        }

        private static Page WrapInNavigation(Page page)
        {
            return new NavigationPage(page)
            {
                BarBackgroundColor = Color.FromHex("#3F51B5"),
                BarTextColor = Color.White
            };
        }
    }
}
