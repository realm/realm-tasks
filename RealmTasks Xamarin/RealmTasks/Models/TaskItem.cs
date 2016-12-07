using Realms;

namespace RealmTasks
{
    [MapTo("Task")]
    public class TaskItem : RealmObject
    {
        [MapTo("text")]
        public string Title { get; set; }

        [MapTo("completed")]
        public bool IsCompleted { get; set; }

        private bool _isEditing;
        public bool IsEditing
        {
            get
            {
                return _isEditing;
            }
            set
            {
                _isEditing = value;
                RaisePropertyChanged();
            }
        }
    }
}