using System.Collections.Generic;
using Realms;

namespace RealmTasks
{
    public class TaskListList : RealmObject
    {
        [PrimaryKey]
        [MapTo("id")]
        public int Id { get; set; }

        [MapTo("items")]
        public IList<TaskListReference> Items { get; }
    }
}
