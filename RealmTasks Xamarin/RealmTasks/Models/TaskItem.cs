using Realms;

namespace RealmTasks
{
    public class Task : RealmObject
    {
        [MapTo("text")]
        [Required]
        public string Title { get; set; } = string.Empty;

        [MapTo("completed")]
        public bool IsCompleted { get; set; }
    }
}