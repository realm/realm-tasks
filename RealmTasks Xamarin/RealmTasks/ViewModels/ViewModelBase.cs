using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using Xamarin.Forms;

using ThreadingTask = System.Threading.Tasks.Task;

namespace RealmTasks
{
    public abstract class ViewModelBase : INotifyPropertyChanged
    {
        private bool _initialized;
        private bool _isBusy;

        public event PropertyChangedEventHandler PropertyChanged;

        protected INavigationService NavigationService => DependencyService.Get<INavigationService>(DependencyFetchTarget.GlobalInstance);

        protected IDialogService DialogService => DependencyService.Get<IDialogService>(DependencyFetchTarget.GlobalInstance);

        protected bool IsBusy
        {
            get
            {
                return _isBusy;
            }
            set
            {
                if (_isBusy != value)
                {
                    _isBusy = value;
                    OnBusyChanged();
                }
            }
        }

        protected void RaisePropertyChanged([CallerMemberName] string property = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(property));
        }

        protected bool Set<T>(ref T field, T value, [CallerMemberName] string property = null)
        {
            if (field?.Equals(value) != true)
            {
                field = value;
                RaisePropertyChanged(property);
                return true;
            }

            return false;
        }

        public void Initialize()
        {
            if (!_initialized)
            {
                _initialized = true;
                InitializeCore();
            }
        }

        protected virtual void InitializeCore()
        {
        }

        protected virtual void OnBusyChanged()
        {
        }

        protected void HandleException(Exception ex)
        {
            Console.WriteLine(ex);
        }

        protected async void PerformTask(Func<ThreadingTask> func, Func<Exception, ThreadingTask> onError = null, string progressMessage = null)
        {
            IsBusy = true;
            if (progressMessage != null)
            {
                DialogService.ShowProgress(progressMessage);
            }

            try
            {
                await func();
            }
            catch (Exception ex)
            {
                if (onError == null)
                {
                    HandleException(ex);
                }
                else
                {
                    await onError(ex);
                }
            }
            finally
            {
                IsBusy = false;
                if (progressMessage != null)
                {
                    DialogService.HideProgress();
                }
            }
        }
    }
}