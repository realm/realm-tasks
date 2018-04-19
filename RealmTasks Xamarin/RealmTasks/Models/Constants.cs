using System;
using Xamarin.Forms;

namespace RealmTasks
{
    public static class Constants
    {
        public const string DefaultListName = "My Tasks";
        public const string DefaultListId = "80EB1620-165B-4600-A1B1-D97032FDD9A0";

        public static class Server
        {
            public static string SyncHost { get; set; } = "127.0.0.1:9080";

            public static Uri SyncServerUri => new Uri($"realms://{SyncHost}/~/realmtasks");

            public static Uri AuthServerUri => new Uri($"https://{SyncHost}");
        }

        public static class Colors
        {
            public static readonly Color[] ListColors =
            {
                new Color(06 / 255.0, 147 / 255.0, 251 / 255.0),
                new Color(16 / 255.0, 158 / 255.0, 251 / 255.0),
                new Color(26 / 255.0, 169 / 255.0, 251 / 255.0),
                new Color(33 / 255.0, 180 / 255.0, 251 / 255.0),
                new Color(40 / 255.0, 190 / 255.0, 251 / 255.0),
                new Color(46 / 255.0, 198 / 255.0, 251 / 255.0),
                new Color(54 / 255.0, 207 / 255.0, 251 / 255.0)
            };

            public static readonly Color[] TaskColors =
            {
                new Color(231 / 255.0, 167 / 255.0, 118 / 255.0),
                new Color(228 / 255.0, 125 / 255.0, 114 / 255.0),
                new Color(233 / 255.0, 099 / 255.0, 111 / 255.0),
                new Color(242 / 255.0, 081 / 255.0, 145 / 255.0),
                new Color(154 / 255.0, 080 / 255.0, 164 / 255.0),
                new Color(088 / 255.0, 086 / 255.0, 157 / 255.0),
                new Color(056 / 255.0, 071 / 255.0, 126 / 255.0)
            };

            public static readonly Color CompletedColor = new Color(51 / 255.0, 51 / 255.0, 51 / 255.0);
        }

        public static class ADCredentials
        {
            public const string ClientId = "your-client-id";
            public const string CommonAuthority = "https://login.windows.net/common";
            public static Uri RedirectUri = new Uri("http://your-redirect-uri");
        }
    }
}
