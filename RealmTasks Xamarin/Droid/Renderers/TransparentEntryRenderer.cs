using Android.Graphics;
using Android.Text;
using Android.Views;
using RealmTasks;
using RealmTasks.Droid;
using Xamarin.Forms;
using Xamarin.Forms.Platform.Android;

[assembly: ExportRenderer(typeof(TransparentEntry), typeof(TransparentEntryRenderer))]
namespace RealmTasks.Droid
{
    public class TransparentEntryRenderer : EntryRenderer
    {
        protected override void OnElementChanged(ElementChangedEventArgs<Entry> e)
        {
            base.OnElementChanged(e);

            if (Control != null)
            {
                Control.Gravity = GravityFlags.CenterVertical | GravityFlags.Left;
                Control.SetBackgroundColor(Android.Graphics.Color.Transparent);
                Control.InputType |= InputTypes.TextFlagNoSuggestions;
                Control.SetPadding(25, Control.PaddingTop, Control.PaddingRight, Control.PaddingBottom);

                UpdateStrikeThrough(e.NewElement as TransparentEntry);
            }
        }

        private void UpdateStrikeThrough(TransparentEntry entry)
        {
            if (entry?.IsStrikeThrough == true)
            {
                Control.PaintFlags |= PaintFlags.StrikeThruText;
            }
            else
            {
                Control.PaintFlags &= ~PaintFlags.StrikeThruText;
            }
        }
    }
}