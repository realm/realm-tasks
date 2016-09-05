/*
 * Copyright 2016 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.realm.realmtasks.list;

import android.support.v7.widget.RecyclerView;

import java.util.List;

import io.realm.Realm;
import io.realm.RealmList;
import io.realm.realmtasks.model.TaskList;

public class TasksListAdapter extends TasksCommonAdapter<TaskList> {

    public TasksListAdapter(List<TaskList> items) {
        super(items);
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
        super.onBindViewHolder(holder, position);
        final TasksViewHolder tasksViewHolder = (TasksViewHolder) holder;
        final TaskList taskList = items.get(position);
        tasksViewHolder.getText().setText(taskList.getText());
        tasksViewHolder.setStrike(taskList.isCompleted());
    }

    @Override
    public void onItemAdd() {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm bgRealm) {
                final TaskList taskList = realm.createObject(TaskList.class);
                taskList.setText("Added");
                items.add(0, taskList);
            }
        });
        realm.close();
        super.onItemAdd();
    }

    @Override
    public boolean onItemMove(final int fromPosition, final int toPosition) {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm bgRealm) {
                moveItems(fromPosition, toPosition);
            }
        });
        realm.close();
        return super.onItemMove(fromPosition, toPosition);
    }

    @Override
    public void onItemArchive(final int position) {
        final TaskList taskList = items.get(position);
        final Realm realm = Realm.getDefaultInstance();
        final int count = (int) ((RealmList<TaskList>) items).where().equalTo("completed", false).count();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm bgRealm) {
                if (!taskList.isCompleted() && taskList.isCompetable()) {
                    taskList.setCompleted(true);
                    moveItems(position, count - 1);
                } else {
                    taskList.setCompleted(false);
                    moveItems(position, count);
                }
            }
        });
        super.onItemArchive(position);
    }

    @Override
    public void onItemDismiss(final int position) {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm bgRealm) {
                items.remove(position);
            }
        });
        realm.close();
        super.onItemDismiss(position);
    }

    @Override
    public void onCancelAdding() {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm bgRealm) {
                items.remove(0);
            }
        });
        realm.close();
        super.onCancelAdding();
    }
}
