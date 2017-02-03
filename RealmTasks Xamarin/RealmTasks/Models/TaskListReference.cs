using System;
using Realms;
using Realms.Sync;

namespace RealmTasks
{
    public class TaskListReference : RealmObject, ICompletable
    {
        private TaskList _list;

        [PrimaryKey]
        [Required]
        [MapTo("id")]
        public string Id { get; set; } = Guid.NewGuid().ToString();

        [MapTo("fullServerPath")]
        public string FullServerPath { get; set; }

        [Ignored]
        public TaskList List
        {
            get
            {
                if (_list == null)
                {
                    var realm = GetListRealm();
                    realm.Write(() =>
                    {
                        _list = realm.Find<TaskList>(0);
                        if (_list == null)
                        {
                            _list = realm.Add(new TaskList());
                        }
                    });
                }

                return _list;
            }
        }

        [Ignored]
        public bool IsCompleted
        {
            get
            {
                return List.IsCompleted;
            }
            set
            {
                List.Realm.Write(() =>
                {
                    List.IsCompleted = value;
                });

                RaisePropertyChanged();
            }
        }

        ~TaskListReference()
        {
            if (_list != null)
            {
                _list.Realm.Dispose();
                _list = null;
            }
        }

        private Realm GetListRealm()
        {
            var user = ((SyncConfiguration)Realm.Config).User;
            var url = Constants.Server.GetSyncServerUri(FullServerPath ?? $"/~/list-{Id}");
            var config = new SyncConfiguration(user, url)
            {
                ObjectClasses = new[] { typeof(TaskList), typeof(Task) }
            };

            return Realm.GetInstance(config);
        }
    }
}
