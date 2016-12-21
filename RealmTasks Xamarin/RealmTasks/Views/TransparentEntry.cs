using Xamarin.Forms;

namespace RealmTasks
{
    public class TransparentEntry : Entry
    {
        public static readonly BindableProperty IsStrikeThroughProperty = BindableProperty.Create(nameof(IsStrikeThrough), typeof(bool), typeof(TransparentEntry), false);

        public bool IsStrikeThrough
        {
            get
            {
                return (bool)GetValue(IsStrikeThroughProperty);
            }
            set
            {
                SetValue(IsStrikeThroughProperty, value);
            }
        }
    }
}