using System;
#if !__MAC__
using Acr.UserDialogs;
#endif
using RealmTasks;
using Xamarin.Forms;

[assembly: Dependency(typeof(DialogService))]

namespace RealmTasks
{
    public class DialogService : IDialogService
    {
        public void HideProgress()
        {
#if !__MAC__
            UserDialogs.Instance.HideLoading();
#endif
        }

        public void ShowProgress(string message)
        {
#if !__MAC__
			UserDialogs.Instance.ShowLoading(message);
#endif
		}

        public void Alert(string title, string message)
        {
#if !__MAC__
			UserDialogs.Instance.Alert(message, title);
#endif
		}
    }
}
