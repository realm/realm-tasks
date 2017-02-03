using System.Linq;
using Realms;
using Xamarin.Forms;

namespace RealmTasks
{
    public class TasksViewModel : ViewModelBase
    {
        private TaskList _taskList;

        public TaskListReference TaskListReference { get; private set; }

        public TaskList TaskList
        {
            get
            {
                return _taskList;
            }
            set
            {
                Set(ref _taskList, value);
            }
        }

        public Command<Task> DeleteTaskCommand { get; }

        public Command<Task> CompleteTaskCommand { get; }

        public Command AddTaskCommand { get; }

        private Realm TaskListRealm => TaskList?.Realm;

        public TasksViewModel()
        {
            DeleteTaskCommand = new Command<Task>(DeleteTask);
            CompleteTaskCommand = new Command<Task>(CompleteTask);
            AddTaskCommand = new Command(AddTask);
        }

        public void Setup(TaskListReference listReference)
        {
            TaskListReference = listReference;
            TaskList = TaskListReference.List;
        }

        public override void OnDisappearing()
        {
            // var realm = TaskListRealm;
            // TaskList = null;
            // realm?.Dispose();
        }

        private void DeleteTask(Task task)
        {
            if (task != null)
            {
                TaskListRealm?.Write(() =>
                {
                    TaskListRealm.Remove(task);
                });
            }
        }

        private void CompleteTask(Task task)
        {
            if (task != null)
            {
                TaskListRealm?.Write(() =>
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
            TaskListRealm?.Write(() =>
            {
                TaskList.Items.Insert(0, new Task());
            });
        }
    }
}