using System.Linq;
using Realms;
#if !WPF
using Xamarin.Forms;
#endif

namespace RealmTasks
{
    public class TasksViewModel : ViewModelBase
    {
        private Realm _realm;

        public TaskList TaskList { get; private set; }

        public Command<Task> DeleteTaskCommand { get; }
        public Command<Task> CompleteTaskCommand { get; }
        public Command AddTaskCommand { get; }

        public TasksViewModel()
        {
            DeleteTaskCommand = new Command<Task>(DeleteTask);
            CompleteTaskCommand = new Command<Task>(CompleteTask);
            AddTaskCommand = new Command(AddTask);
        }

        public void Setup(Realm realm, string taskListId)
        {
            _realm = realm;
            TaskList = realm.Find<TaskList>(taskListId);
            RaisePropertyChanged(nameof(TaskList));
        }

        private void DeleteTask(Task task)
        {
            if (task != null)
            {
                _realm.Write(() =>
                {
                    _realm.Remove(task);
                });
            }
        }

        private void CompleteTask(Task task)
        {
            if (task != null)
            {
                _realm.Write(() =>
                {
                    task.IsCompleted = !task.IsCompleted;
                    int index;
                    if (task.IsCompleted)
                    {
                        index = TaskList.Items.Count;
                    }
                    else
                    {
                        index = TaskList.Items.Count(t => !t.IsCompleted);
                    }

                    TaskList.Items.Move(task, index - 1);
                });
            }
        }

        private void AddTask()
        {
            _realm.Write(() =>
            {
                TaskList.Items.Insert(0, new Task());
            });
        }
    }
}