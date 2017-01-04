using System;
using System.Windows.Input;

namespace RealmTasks
{
    public class Command<T> : ICommand
    {
        private readonly Action<T> _action;

        public event EventHandler CanExecuteChanged;

        public Command(Action<T> action)
        {
            _action = action;
        }

        public bool CanExecute(object parameter)
        {
            throw new NotImplementedException();
        }

        public void Execute(object parameter)
        {
            _action((T)parameter);
        }
    }

    public class Command : ICommand
    {
        private readonly Action _action;

        public event EventHandler CanExecuteChanged;

        public Command(Action action)
        {
            _action = action;
        }

        public bool CanExecute(object parameter)
        {
            throw new NotImplementedException();
        }

        public void Execute(object parameter)
        {
            _action();
        }
    }
}
