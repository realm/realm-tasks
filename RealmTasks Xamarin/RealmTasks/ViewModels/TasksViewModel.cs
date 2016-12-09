using System;
using System.Linq;
using Realms;
using Xamarin.Forms;

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
            Title = TaskList?.Title;
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
                    TaskList.Items.Remove(task);
                    task.IsCompleted = !task.IsCompleted;
                    if (task.IsCompleted)
                    {
                        TaskList.Items.Add(task);
                    }
                    else
                    {
                        var nonCompletedCount = TaskList.Items.Count(t => !t.IsCompleted);
                        TaskList.Items.Insert(nonCompletedCount, task);
                    }
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