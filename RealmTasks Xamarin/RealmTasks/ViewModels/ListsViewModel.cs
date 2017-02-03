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
        private IList<TaskListReference> _taskLists;
        private bool _initialized;

        public IList<TaskListReference> TaskLists
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

        public Command<TaskListReference> DeleteTaskListCommand { get; }

        public Command<TaskListReference> CompleteTaskListCommand { get; }

        public Command<TaskListReference> OpenTaskListCommand { get; }

        public Command AddTaskListCommand { get; }

        public Command LogoutCommand { get; }

        public ListsViewModel()
        {
            DeleteTaskListCommand = new Command<TaskListReference>(DeleteList);
            CompleteTaskListCommand = new Command<TaskListReference>(CompleteList);
            OpenTaskListCommand = new Command<TaskListReference>(OpenList);
            AddTaskListCommand = new Command(AddList);
            LogoutCommand = new Command(Logout);
        }

        public override async void OnAppearing()
        {
            if (_initialized)
            {
                return;
            }

            _initialized = true;
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
                var config = new SyncConfiguration(user, Constants.Server.GetSyncServerUri("/~/lists"))
                {
                    ObjectClasses = new[] { typeof(TaskListList), typeof(TaskListReference) }
                };

                _realm = Realm.GetInstance(config);

                TaskListList parent = null;
                _realm.Write(() =>
                {
                    // Eagerly acquire write-lock to ensure we don't get into
                    // race conditions with sync writing data in the background
                    parent = _realm.Find<TaskListList>(0);
                    if (parent == null)
                    {
                        parent = _realm.Add(new TaskListList());
                        var taskListReference = new TaskListReference
                        { 
                            Id = Constants.DefaultListId
                        };

                        parent.Items.Add(taskListReference);

                        taskListReference.List.Realm.Write(() =>
                        {
                            taskListReference.List.Title = Constants.DefaultListName;
                        });
                    }
                });

                TaskLists = parent.Items;
            }
            catch (Exception ex)
            {
                HandleException(ex);
            }
        }

        private void DeleteList(TaskListReference listReference)
        {
            if (listReference != null)
            {
                _realm.Write(() =>
                {
                    _realm.Remove(listReference);
                });
            }
        }

        private void CompleteList(TaskListReference listReference)
        {
            if (listReference != null)
            {
                _realm.Write(() =>
                {
                    listReference.IsCompleted = !listReference.IsCompleted;

                    int index;
                    if (listReference.IsCompleted)
                    {
                        index = TaskLists.Count;
                    }
                    else
                    {
                        index = TaskLists.Count(t => !t.IsCompleted);
                    }

                    TaskLists.Move(listReference, index - 1);
                });
            }
        }

        private void OpenList(TaskListReference listReference)
        {
            if (listReference != null)
            {
                PerformTask(async () =>
                {
                    await NavigationService.Navigate<TasksViewModel>(vm => vm.Setup(listReference));
                });
            }
        }

        private void AddList()
        {
            _realm.Write(() =>
            {
                TaskLists.Insert(0, new TaskListReference());
            });
        }

        private void Logout()
        {
            User.Current.LogOut();
            NavigationService.SetMainPage<ListsViewModel>();
        }
    }
}