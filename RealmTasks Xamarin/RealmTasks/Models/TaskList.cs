using System.Collections.Generic;
using Realms;

namespace RealmTasks
{
    public class TaskList : RealmObject
    {
        [PrimaryKey]
        [MapTo("id")]
        public int Id { get; set; }

        [MapTo("items")]
        public IList<Task> Items { get; }

        [MapTo("text")]
        [Required]
        public string Title { get; set; } = string.Empty;

        [MapTo("completed")]
        public bool IsCompleted { get; set; }
    }
}
