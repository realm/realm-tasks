using System;
using System.Threading.Tasks;

using ThreadingTask = System.Threading.Tasks.Task;

namespace RealmTasks
{
    public interface INavigationService
    {
        ThreadingTask Navigate<T>(Action<T> setup = null) where T : ViewModelBase;

        ThreadingTask GoBack();

        void SetMainPage<T>(bool navigatable) where T : ViewModelBase;

        System.Threading.Tasks.Task<TResult> Prompt<TViewModel, TResult>() where TViewModel : ViewModelBase, IPromptable<TResult>;
    }
}