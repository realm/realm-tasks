/*
 * Copyright 2016 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.realm.realmtasks;

import android.app.Application;
import android.support.annotation.NonNull;

import io.realm.Realm;
import io.realm.RealmConfiguration;
import io.realm.realmtasks.model.TaskList;
import io.realm.realmtasks.model.TaskListList;

public class TasksApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        Realm.setDefaultConfiguration(buildRealmConfigutation());
        populateDefaultList();
    }

    private void populateDefaultList() {
        final Realm realm = Realm.getDefaultInstance();
        if (realm.isEmpty()) {
            realm.executeTransaction(new Realm.Transaction() {
                @Override
                public void execute(Realm realm) {
                    final TaskListList taskListList = realm.createObject(TaskListList.class);
                    final TaskList taskList = new TaskList();
                    taskList.setId(TaskList.DEFAULT_ID);
                    taskList.setText(TaskList.DEFAULT_LIST_NAME);
                    taskListList.getItems().add(taskList);
                }
            });
        }
        realm.close();
    }

    @NonNull
    private RealmConfiguration buildRealmConfigutation() {
        return new RealmConfiguration.Builder(this).build();
    }
}
