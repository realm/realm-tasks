using System;
using System.Collections.Generic;
using Realms;

namespace RealmTasks
{
    public class TaskList : RealmObject
    {
        [PrimaryKey]
        [Required]
        [MapTo("id")]
        public string Id { get; set; } = Guid.NewGuid().ToString();

        [MapTo("text")]
        [Required]
        public string Title { get; set; } = string.Empty;

        [MapTo("completed")]
        public bool IsCompleted { get; set; }

        [MapTo("items")]
        public IList<Task> Items { get; }
    }
}
