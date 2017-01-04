using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Interactivity;
using System.Windows.Media;
using Realms;

using ThreadingTask = System.Threading.Tasks.Task;

namespace RealmTasks
{
    public class ItemColoringBehavior<T> : Behavior<Control> where T : RealmObject, ICompletable
    {
        private IDisposable _notificationToken;

        public static DependencyProperty RealmCollectionProperty =
            DependencyProperty.Register(nameof(RealmCollection), typeof(IList<T>), typeof(ItemColoringBehavior<T>), new PropertyMetadata(new PropertyChangedCallback(OnRealmCollectionChanged)));

        public IList<T> RealmCollection
        {
            get
            {
                return (IList<T>)GetValue(RealmCollectionProperty);
            }
            set
            {
                SetValue(RealmCollectionProperty, value);
                CalculateColor();
            }
        }

        public Color[] Colors { get; set; }

        public Color CompletedColor { get; set; }

        static void OnRealmCollectionChanged(DependencyObject bindable, DependencyPropertyChangedEventArgs args)
        {
            var self = (ItemColoringBehavior<T>)bindable;
            self._notificationToken?.Dispose();

            var newCollection = args.NewValue as IRealmCollection<T>;
            self._notificationToken = newCollection?.SubscribeForNotifications(delegate { self.CalculateColor(); });
        }

        protected override void OnAttached()
        {
            base.OnAttached();

            CalculateColor();
        }

        protected override void OnDetaching()
        {
            base.OnDetaching();

            _notificationToken?.Dispose();
        }

        private async void CalculateColor()
        {
            // HACK: yield control to avoid a race condition where things might not be initialized yet, resulting in no color being applied
            await ThreadingTask.Delay(1);
            T item;
            if (RealmCollection != null &&
                AssociatedObject != null &&
                (item = AssociatedObject.DataContext as T) != null)
            {
                try
                {
                    Color backgroundColor;
                    if (item.IsCompleted)
                    {
                        backgroundColor = CompletedColor;
                    }
                    else
                    {
                        var index = RealmCollection.IndexOf(item);
                        var fraction = index / (double)Math.Max(13, RealmCollection.Count);
                        backgroundColor = GradientColorAtFraction(fraction);
                    }

                    AssociatedObject.Background = new SolidColorBrush(backgroundColor);
                }
                catch
                {
                    // Let's not crash because of a coloring fail :)
                }
            }
        }

        private Color GradientColorAtFraction(double fraction)
        {
            // Ensure offset is normalized to 1
            var normalizedOffset = Math.Max(Math.Min(fraction, 1), 0);

            // Work out the 'size' that each color stop spans
            var colorStopRange = 1.0 / (Colors.Length - 1);

            // Determine the base stop our offset is within
            var colorRangeIndex = (int)Math.Floor(normalizedOffset / colorStopRange);

            // Get the initial color which will serve as the origin
            var topColor = Colors[colorRangeIndex];
            var fromColors = new[] { topColor.R, topColor.G, topColor.B };
            // Get the destination color we will lerp to
            var bottomColor = Colors[colorRangeIndex + 1];
            var toColors = new[] { bottomColor.R, bottomColor.G, bottomColor.B };

            // Work out the actual percentage we need to lerp, inside just that stop range
            var stopOffset = (normalizedOffset - colorRangeIndex * colorStopRange) / colorStopRange;

            return Color.FromRgb(
                (byte)(255 * (fromColors[0] + stopOffset * (toColors[0] - fromColors[0]))),
                (byte)(255 * (fromColors[1] + stopOffset * (toColors[1] - fromColors[1]))),
                (byte)(255 * (fromColors[2] + stopOffset * (toColors[2] - fromColors[2]))));
        }
    }
}
