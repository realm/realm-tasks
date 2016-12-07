using System;

namespace RealmTasks
{
    public static class Constants
    {
        public static class Names
        {
            public const string DefaultListName = "My Tasks";
        }

        public static class Server
        {
            public static string SyncHost { get; set; } = "127.0.0.1:9080";

            public static Uri SyncServerUri => new Uri($"realm://{SyncHost}/~/realmtasks");
            public static Uri AuthServerUri => new Uri($"http://{SyncHost}");
        }
    }
}
