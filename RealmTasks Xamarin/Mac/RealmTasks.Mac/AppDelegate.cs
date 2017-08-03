using AppKit;
using Foundation;
using Xamarin.Forms;
using Xamarin.Forms.Platform.MacOS;

namespace RealmTasks.Mac
{
    [Register("AppDelegate")]
    public class AppDelegate : FormsApplicationDelegate
    {
        public override NSWindow MainWindow { get; }

        public AppDelegate()
        {
			var style = NSWindowStyle.Closable | NSWindowStyle.Resizable | NSWindowStyle.Titled;

			var rect = new CoreGraphics.CGRect(200, 1000, 1024, 768);
            MainWindow = new NSWindow(rect, style, NSBackingStore.Buffered, false)
            {
                Title = "Realm Tasks",
                TitleVisibility = NSWindowTitleVisibility.Visible
            };
        }

        public override void DidFinishLaunching(NSNotification notification)
        {
			Forms.Init();
			LoadApplication(new App());
			base.DidFinishLaunching(notification);
        }
    }
}
