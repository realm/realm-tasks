using System;
using System.Collections.Generic;
using Realms;
using Realms.Sync;
using Xamarin.Forms;

namespace RealmTasks
{
    public class ListsViewModel : ViewModelBase
    {
        private Realm _realm;
        private IList<TaskList> _taskLists;

        public IList<TaskList> TaskLists
        {
            get
            {
                return _taskLists;
            }

            set
            {
                Set(ref _taskLists, value);
            }
        }

        public TaskList SelectedTaskList
        {
            get
            {
                return null;
            }
            set
            {
                if (value != null)
                {
                    NavigateToList(value);
                }
            }
        }

        public Command<TaskList> DeleteTaskListCommand { get; }
        public Command<TaskList> EditTaskListCommand { get; }
        public Command AddTaskListCommand { get; }

        public ListsViewModel()
        {
            DeleteTaskListCommand = new Command<TaskList>(DeleteList);
            EditTaskListCommand = new Command<TaskList>(EditList);
            AddTaskListCommand = new Command(AddList);

            Title = "Tasks";
        }

        protected override async void InitializeCore()
        {
            User user = null;

            try
            {
                user = User.Current;
            }
            catch (Exception ex)
            {
                HandleException(ex);
            }

            if (user == null)
            {
                try
                {
                    user = await NavigationService.Prompt<LoginViewModel, User>();
                }
                catch (Exception ex)
                {
                    HandleException(ex);
                }
            }
            else
            {
                var uri = user.ServerUri;
                Constants.Server.SyncHost = $"{uri.Host}:{uri.Port}";
            }

            try
            {
                var config = new SyncConfiguration(user, Constants.Server.SyncServerUri);
                _realm = Realm.GetInstance(config);
                var parent = _realm.Find<TaskListList>(0);
                if (parent == null)
                {
                    _realm.Write(() =>
                    {
                        parent = _realm.Add(new TaskListList());
                    });
                }

                if (parent.Items.Count == 0)
                {
                    _realm.Write(() =>
                    {
                        parent.Items.Add(new TaskList
                        {
                            Id = Guid.NewGuid().ToString(),
                            Title = Constants.Names.DefaultListName
                        });
                    });
                }

                TaskLists = parent.Items;
            }
            catch (Exception ex)
            {
                HandleException(ex);
            }
        }

        private void DeleteList(TaskList list)
        {
            if (list != null)
            {
                _realm.Write(() =>
                {
                    _realm.Remove(list);
                });
            }
        }

        private void EditList(TaskList list)
        {
            if (list != null)
            {
                list.IsEditing = true;
            }
        }

        private void AddList()
        {
            _realm.Write(() =>
            {
                TaskLists.Insert(0, new TaskList
                {
                    Id = Guid.NewGuid().ToString()
                });
            });
        }

        private void NavigateToList(TaskList list)
        {
            PerformTask(async () =>
            {
                await NavigationService.Navigate<TasksViewModel>(vm => vm.Setup(_realm, list.Id));
            });
        }
    }
}