using System;
using Realms;
using Xamarin.Forms;

namespace RealmTasks
{
    public class TasksViewModel : ViewModelBase
    {
        private Realm _realm;
        private TaskList _taskList;

        public TaskList TaskList
        {
            get
            {
                return _taskList;
            }
            private set
            {
                if (Set(ref _taskList, value))
                {
                    Title = _taskList?.Title;
                }
            }
        }

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
                });
            }
        }

        private void AddTask()
        {
            _realm.Write(() =>
            {
                if (TaskList.Items.Count == 0)
                {
                    TaskList.Items.Add(new Task());
                }
                else
                {
                    TaskList.Items.Insert(0, new Task());
                }
            });
        }
    }
}