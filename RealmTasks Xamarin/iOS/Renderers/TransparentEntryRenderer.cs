using CoreGraphics;
using RealmTasks;
using RealmTasks.iOS;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer(typeof(TransparentEntry), typeof(TransparentEntryRenderer))]
namespace RealmTasks.iOS
{
    public class TransparentEntryRenderer : EntryRenderer
    {
        protected override void OnElementChanged(ElementChangedEventArgs<Entry> e)
        {
            base.OnElementChanged(e);

            if (Control != null)
            {
                Control.BorderStyle = UITextBorderStyle.None;
                Control.BackgroundColor = UIColor.Clear;
                Control.TintColor = UIColor.White;
                Control.LeftView = new UIView(new CGRect(0, 0, 15, 10));
                Control.LeftViewMode = UITextFieldViewMode.Always;
            }
        }
    }
}