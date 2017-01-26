using System;
using System.Globalization;
using Xamarin.Forms;

namespace RealmTasks
{
    public class TaskListToAlphaConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var list = value as TaskList;
            if (list != null &&
                !list.IsCompleted &&
                list.Items.Count == 0)
            {
                return 0.9;
            }

            return 1;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotSupportedException();
        }
    }
}
