using System;
using System.Collections.Generic;
using System.Linq;
using Realms;
#if !WPF
using Realms.Sync;
using Xamarin.Forms;
#endif

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
        }

        protected override async void InitializeCore()
        {
#if !WPF
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

#endif
            try
            {
#if WPF
                var config = new RealmConfiguration
                {
                    ObjectClasses = new[] { typeof(Task), typeof(TaskList), typeof(TaskListList) }
                };

#else
                var config = new SyncConfiguration(user, Constants.Server.SyncServerUri)
                {
                    ObjectClasses = new[] { typeof(Task), typeof(TaskList), typeof(TaskListList) }
                };
#endif

                _realm = Realm.GetInstance(config);

                var parent = _realm.Find<TaskListList>(0);
                if (parent == null)
                {
                    try
                    {
                        _realm.Write(() =>
                        {
                            parent = new TaskListList();
                            parent.Items.Add(new TaskList
                            {
                                Id = Constants.DefaultListId,
                                Title = Constants.DefaultListName
                            });

                            _realm.Add(parent);
                        });
                    }
                    catch (RealmDuplicatePrimaryKeyValueException)
                    {
                        // If sync went through too fast, we might already have that one.
                        // We don't care though, since we only use it as container.
                        parent = _realm.Find<TaskListList>(0);
                    }
                }

                TaskLists = parent.Items;
                await System.Threading.Tasks.Task.Delay(1000);

                var trans = _realm.BeginWrite();
                await System.Threading.Tasks.Task.Delay(10000);
                trans.Commit();
                DialogService.Alert("saved", "saved");
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
                    list.IsCompleted = !list.IsCompleted;
                    int index;
                    if (list.IsCompleted)
                    {
                        index = TaskLists.Count;
                    }
                    else
                    {
                        index = TaskLists.Count(t => !t.IsCompleted);
                    }

                    TaskLists.Move(list, index - 1);
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
#if WPF
            throw new NotSupportedException("Sync is not yet supported.");
#else
            User.Current.LogOut();
            NavigationService.SetMainPage<ListsViewModel>();
#endif
        }
    }
}