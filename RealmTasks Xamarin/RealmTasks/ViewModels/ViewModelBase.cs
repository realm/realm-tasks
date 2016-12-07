using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace RealmTasks
{
    public abstract class ViewModelBase : INotifyPropertyChanged
    {
        private bool _initialized;
        private bool _isBusy;
        private string _title;

        public event PropertyChangedEventHandler PropertyChanged;

        public string Title
        {
            get
            {
                return _title;
            }
            set
            {
                if (_title != value)
                {
                    _title = value;
                    RaisePropertyChanged();
                }
            }
        }

        protected INavigationService NavigationService => DependencyService.Get<INavigationService>(DependencyFetchTarget.GlobalInstance);

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

        protected async void PerformTask(Func<Task> func, Action<Exception> onError = null)
        {
            IsBusy = true;
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
            }
        }
    }
}