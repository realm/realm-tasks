using System;
using System.Collections.Generic;
using System.Linq;
using Realms;
using Realms.Sync;

namespace RealmTasks
{
    public class ListsViewModel : ViewModelBase
    {
        private Realm _realm;
        private IEnumerable<TaskList> _taskLists;

        public IEnumerable<TaskList> TaskLists
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

        protected override async void InitializeCore()
        {
            // TODO: once we implement User.Current, use that to check if user has already logged in.

            try
            {
                var user = await NavigationService.Prompt<LoginViewModel, User>();
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
                // TODO: handle
                Console.WriteLine(ex.Message);
            }
        }
    }
}