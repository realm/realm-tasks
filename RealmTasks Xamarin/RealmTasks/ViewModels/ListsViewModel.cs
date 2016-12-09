using System;
using System.Collections.Generic;
using System.Linq;
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

        public Command<TaskList> DeleteTaskListCommand { get; }
        public Command<TaskList> CompleteTaskListCommand { get; }
        public Command<TaskList> OpenTaskListCommand { get; }
        public Command AddTaskListCommand { get; }
        public Command LogoutCommand { get; }

        public ListsViewModel()
        {
            DeleteTaskListCommand = new Command<TaskList>(DeleteList);
            CompleteTaskListCommand = new Command<TaskList>(CompleteList);
            OpenTaskListCommand = new Command<TaskList>(OpenList);
            AddTaskListCommand = new Command(AddList);
            LogoutCommand = new Command(Logout);

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
                var config = new SyncConfiguration(user, Constants.Server.SyncServerUri)
                {
                    ObjectClasses = new[] { typeof(Task), typeof(TaskList), typeof(TaskListList) }
                };
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

        private void CompleteList(TaskList list)
        {
            if (list != null)
            {
                _realm.Write(() =>
                {
                    TaskLists.Remove(list);
                    list.IsCompleted = !list.IsCompleted;
                    if (list.IsCompleted)
                    {
                        TaskLists.Add(list);
                    }
                    else
                    {
                        var nonCompletedCount = TaskLists.Count(t => !t.IsCompleted);
                        TaskLists.Insert(nonCompletedCount, list);
                    }
                });
            }
        }

        private void OpenList(TaskList list)
        {
            if (list != null)
            {
                PerformTask(async () =>
                {
                    await NavigationService.Navigate<TasksViewModel>(vm => vm.Setup(_realm, list.Id));
                });
            }
        }

        private void AddList()
        {
            _realm.Write(() =>
            {
                TaskLists.Insert(0, new TaskList());
            });
        }

        private void Logout()
        {
            User.Current.LogOut();
            NavigationService.SetMainPage<ListsViewModel>();
        }
    }
}