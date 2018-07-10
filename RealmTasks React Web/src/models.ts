export interface ITask {
  completed: boolean;
  text: string;
}

export interface ITaskList {
  id: string;
  text: string;
  completed: boolean;
  items: ITask[];
}
