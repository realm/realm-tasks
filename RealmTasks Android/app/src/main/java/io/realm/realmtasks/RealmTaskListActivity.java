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

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;

import io.realm.Realm;
import io.realm.realmtasks.list.TasksListAdapter;
import io.realm.realmtasks.list.TasksTouchHelper;
import io.realm.realmtasks.list.TasksViewHolder;
import io.realm.realmtasks.model.TaskListList;

public class RealmTaskListActivity extends AppCompatActivity {

    private Realm realm;
    private RecyclerView recyclerView;
    private TasksListAdapter adapter;
    private TasksTouchHelper tasksTouchHelper;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_common_list);
        recyclerView = (RecyclerView) findViewById(R.id.recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
    }

    @Override
    protected void onStart() {
        super.onStart();
        realm = Realm.getDefaultInstance();
        adapter = new TasksListAdapter(realm.where(TaskListList.class).findFirst().getItems());
        recyclerView.setAdapter(adapter);
        tasksTouchHelper = new TasksTouchHelper(new Callback());
        tasksTouchHelper.attachToRecyclerView(recyclerView);
    }

    @Override
    protected void onStop() {
        tasksTouchHelper.attachToRecyclerView(null);
        recyclerView.setAdapter(null);
        realm.close();
        super.onStop();
    }

    private class Callback implements TasksTouchHelper.Callback {
        @Override
        public void onMoved(RecyclerView recyclerView, TasksViewHolder from, TasksViewHolder to) {
            adapter.onItemMoved(from.getAdapterPosition(), to.getAdapterPosition());
        }

        @Override
        public void onArchived(TasksViewHolder viewHolder) {
            adapter.onItemArchived(viewHolder.getAdapterPosition());
        }

        @Override
        public void onDismissed(TasksViewHolder viewHolder) {
            adapter.onItemDismissed(viewHolder.getAdapterPosition());
        }

        @Override
        public boolean onItemClicked(TasksViewHolder viewHolder) {
            return false;
        }

        @Override
        public void onItemChanged(TasksViewHolder viewHolder) {
            adapter.onItemChanged(viewHolder);
        }

        @Override
        public void onAdded() {
            adapter.onItemAdded();
        }

        @Override
        public void onReverted() {
            adapter.onItemReverted();
        }

        @Override
        public void onExited() {
            finish();
        }
    }
}
