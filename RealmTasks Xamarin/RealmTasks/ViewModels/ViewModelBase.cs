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

        public event PropertyChangedEventHandler PropertyChanged;

        protected INavigationService NavigationService => DependencyService.Get<INavigationService>(DependencyFetchTarget.GlobalInstance);

        protected void RaisePropertyChanged([CallerMemberName] string property = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(property));
        }

        protected void Set<T>(ref T field, T value, [CallerMemberName] string property = null)
        {
            if (!(field?.Equals(value) ?? false))
            {
                field = value;
                RaisePropertyChanged(property);
            }
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

        protected void HandleException(Exception ex)
        {
            Console.WriteLine(ex.Message);
        }
    }
}