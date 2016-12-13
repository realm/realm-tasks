using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using Xamarin.Forms;

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
            if (!(field?.Equals(value) ?? false))
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
            Console.WriteLine(ex.Message);
        }

        protected async void PerformTask(Func<System.Threading.Tasks.Task> func, Action<Exception> onError = null, string progressMessage = null)
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
                    onError(ex);
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