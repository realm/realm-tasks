using System.Windows;

namespace RealmTasks
{
    public class DialogService : IDialogService
    {
        public void HideProgress()
        {
            // Do nothing
        }

        public void ShowProgress(string message)
        {
            // Do nothing
        }

        public void Alert(string title, string message)
        {
            MessageBox.Show(message, title);
        }
    }
}
