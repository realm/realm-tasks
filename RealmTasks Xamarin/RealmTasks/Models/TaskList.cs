using System.Collections.Generic;
using Realms;

namespace RealmTasks
{
    public class TaskList : RealmObject
    {
        [PrimaryKey]
        [MapTo("id")]
        public string Id { get; set; }

        [MapTo("text")]
        public string Title { get; set; }

        [MapTo("completed")]
        public bool IsCompleted { get; set; }

        [MapTo("items")]
        public IList<TaskItem> Items { get; }
    }
}
