using System;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using ThreadingTask = System.Threading.Tasks.Task;

namespace RealmTasks.Implementation
{
    public class NavigationService : INavigationService
    {
        private static TaskCompletionSource<object> currentNavigationTCS;

        private static Frame mainFrame;
        private static Frame MainFrame
        {
            get
            {
                if (mainFrame == null)
                {
                    mainFrame = (Application.Current.MainWindow as MainWindow)?.MainFrame;

                    if (mainFrame != null)
                    {
                        mainFrame.Navigated += OnMainFrameNavigated;
                    }
                }

                return mainFrame;
            }
        }

        private static void OnMainFrameNavigated(object sender, NavigationEventArgs e)
        {
            currentNavigationTCS?.TrySetResult(null);
            currentNavigationTCS = null;
        }

        public ThreadingTask GoBack()
        {
            if (MainFrame == null)
            {
                throw new NotSupportedException("Set navigatable main page before calling this.");
            }

            MainFrame.GoBack();
            return CreateNavigationTask();
        }

        public ThreadingTask Navigate<T>(Action<T> setup = null) where T : ViewModelBase
        {
            if (MainFrame == null)
            {
                throw new NotSupportedException("Set navigatable main page before calling this.");
            }

            var page = GetPage<T>();
            setup?.Invoke((T)page.ViewModel);
            MainFrame.Navigate(page);
            return CreateNavigationTask();
        }

        public void SetMainPage<T>() where T : ViewModelBase
        {
            MainFrame.Content = GetPage<T>();
        }

        public Task<TResult> Prompt<TViewModel, TResult>() where TViewModel : ViewModelBase, IPromptable<TResult>
        {
            throw new NotSupportedException("Prompting is not supported on WPF yet.");
        }

        private static PageBase GetPage<T>()
        {
            var pageType = typeof(T).Name.Replace("ViewModel", "Page");
            return (PageBase)Activator.CreateInstance(Type.GetType($"RealmTasks.{pageType}"));
        }

        private static ThreadingTask CreateNavigationTask()
        {
            currentNavigationTCS = new TaskCompletionSource<object>();
            return ThreadingTask.WhenAny(currentNavigationTCS.Task, ThreadingTask.Delay(2000));
        }
    }
}
