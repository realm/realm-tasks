using Xamarin.Forms;

namespace RealmTasks
{
    public class CellDeselectingBehavior : Behavior<ListView>
    {
        protected override void OnAttachedTo(ListView bindable)
        {
            base.OnAttachedTo(bindable);
            bindable.ItemSelected += OnItemSelected;
        }

        protected override void OnDetachingFrom(ListView bindable)
        {
            bindable.ItemSelected -= OnItemSelected;
            base.OnDetachingFrom(bindable);
        }

        private void OnItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var listView = (ListView)sender;
            listView.SelectedItem = null;
        }
    }
}