using System;
using System.Threading.Tasks;

namespace RealmTasks
{
    public interface INavigationService
    {
        Task Navigate<T>(Action<T> setup = null) where T : ViewModelBase;

        Task GoBack();

        void SetMainPage<T>(bool navigatable) where T : ViewModelBase;

        Task<TResult> Prompt<TViewModel, TResult>() where TViewModel : ViewModelBase, IPromptable<TResult>;
    }
}