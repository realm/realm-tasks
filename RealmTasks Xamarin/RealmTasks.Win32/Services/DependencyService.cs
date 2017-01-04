using System;
using System.Collections.Generic;

namespace RealmTasks
{
    /// <summary>
    /// Class designed to mimic Xamarin.Forms' dependency service.
    /// </summary>
    public static class DependencyService
    {
        private static IDictionary<Type, object> globalRegistrations = new Dictionary<Type, object>();

        public static T Get<T>(DependencyFetchTarget target)
        {
            if (target == DependencyFetchTarget.GlobalInstance)
            {
                object result;
                if (globalRegistrations.TryGetValue(typeof(T), out result))
                {
                    return (T)result;
                }

                throw new NotSupportedException($"Failed to find implementor instance for {typeof(T).Name}. Did you forget to call Register<{typeof(T).Name}>(instance)?");
            }

            throw new NotSupportedException("Only global instances are supported in the WPF limited implementation.");
        }

        public static void Register<T>(T instance)
        {
            globalRegistrations.Add(typeof(T), instance);
        }
    }

    public enum DependencyFetchTarget
    {
        GlobalInstance
    }
}
