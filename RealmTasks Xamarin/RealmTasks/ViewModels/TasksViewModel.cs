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

        public Command<TaskItem> DeleteTaskCommand { get; }
        public Command<TaskItem> EditTaskCommand { get; }
        public Command AddTaskCommand { get; }

        public TasksViewModel()
        {
            DeleteTaskCommand = new Command<TaskItem>(DeleteTask);
            EditTaskCommand = new Command<TaskItem>(EditTask);
            AddTaskCommand = new Command(AddTask);
        }

        public void Setup(Realm realm, string taskListId)
        {
            _realm = realm;
            TaskList = realm.Find<TaskList>(taskListId);
        }

        private void DeleteTask(TaskItem task)
        {
            if (task != null)
            {
                _realm.Write(() =>
                {
                    _realm.Remove(task);
                });
            }
        }

        private void EditTask(TaskItem task)
        {
            if (task != null)
            {
                task.IsEditing = true;
            }
        }

        private void AddTask()
        {
            _realm.Write(() =>
            {
                if (TaskList.Items.Count == 0)
                {
                    TaskList.Items.Add(new TaskItem());
                }
                else
                {
                    TaskList.Items.Insert(0, new TaskItem());
                }
            });
        }
    }
}