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
            private const string SyncHost = "127.0.0.1";

            public static readonly Uri SyncServerUri = new Uri($"realm://{SyncHost}:9080/~/realmtasks");
            public static readonly Uri AuthServerUri = new Uri($"http://{SyncHost}:9080");
        }
    }
}
