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

package io.realm.realmtasks.model;

import io.realm.RealmList;
import io.realm.RealmObject;
import io.realm.annotations.PrimaryKey;

public class TaskList extends RealmObject implements Competable {
    public static String DEFAULT_ID = "80EB1620-165B-4600-A1B1-D97032FDD9A0";
    public static String DEFAULT_LIST_NAME = "defaultListName";

    private String text;
    private boolean completed;
    @PrimaryKey
    private String id;
    private RealmList<Task> items;

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public RealmList<Task> getItems() {
        return items;
    }

    public void setItems(RealmList<Task> items) {
        this.items = items;
    }

    @Override
    public boolean isCompetable() {
        return true;
//        return getItems().where().equalTo("items.completed", false).findAll().isEmpty();
    }
}
