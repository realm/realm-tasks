using System;
#if WPF
using System.Windows.Media;
# else
using Xamarin.Forms;
# endif

namespace RealmTasks
{
    public static class Constants
    {
        public const string DefaultListName = "My Tasks";
        public const string DefaultListId = "80EB1620-165B-4600-A1B1-D97032FDD9A0";

        public static class Server
        {
            public static string SyncHost { get; set; } = "127.0.0.1:9080";

            public static Uri SyncServerUri => new Uri($"realm://{SyncHost}/~/realmtasks");
            public static Uri AuthServerUri => new Uri($"http://{SyncHost}");
        }

        public static class Colors
        {
            public static readonly Color[] ListColors =
            {
                Color.FromRgb(06, 147, 251),
                Color.FromRgb(16, 158, 251),
                Color.FromRgb(26, 169, 251),
                Color.FromRgb(33, 180, 251),
                Color.FromRgb(40, 190, 251),
                Color.FromRgb(46, 198, 251),
                Color.FromRgb(54, 207, 251)
            };

            public static readonly Color[] TaskColors =
            {
                Color.FromRgb(231, 167, 118),
                Color.FromRgb(228, 125, 114),
                Color.FromRgb(233, 099, 111),
                Color.FromRgb(242, 081, 145),
                Color.FromRgb(154, 080, 164),
                Color.FromRgb(088, 086, 157),
                Color.FromRgb(056, 071, 126)
            };

            public static readonly Color CompletedColor = Color.FromRgb(51, 51, 51);
        }
    }
}
