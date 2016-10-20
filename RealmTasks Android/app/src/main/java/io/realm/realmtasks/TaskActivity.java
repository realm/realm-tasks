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

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.Menu;
import android.view.MenuItem;

import io.realm.Realm;
import io.realm.RealmChangeListener;
import io.realm.RealmResults;
import io.realm.realmtasks.list.ItemViewHolder;
import io.realm.realmtasks.list.TaskAdapter;
import io.realm.realmtasks.list.TouchHelper;
import io.realm.realmtasks.model.TaskList;
import io.realm.realmtasks.view.RecyclerViewWithEmptyViewSupport;

public class TaskActivity extends AppCompatActivity {

    public static final String EXTRA_LIST_ID = "extra.list_id";

    private Realm realm;
    private RecyclerViewWithEmptyViewSupport recyclerView;
    private TaskAdapter adapter;
    private TouchHelper touchHelper;
    private String id;
    RealmResults<TaskList> list;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_common_list);

        recyclerView = (RecyclerViewWithEmptyViewSupport) findViewById(R.id.recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setEmptyView(findViewById(R.id.empty_view));

        final Intent intent = getIntent();
        if (!intent.hasExtra(EXTRA_LIST_ID)) {
            throw new IllegalArgumentException(EXTRA_LIST_ID + " required");
        }
        id = intent.getStringExtra(EXTRA_LIST_ID);
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (touchHelper != null) {
            touchHelper.attachToRecyclerView(null);
        }
        adapter = null;
        realm = Realm.getDefaultInstance();
        list = realm.where(TaskList.class).equalTo(TaskList.FIELD_ID, id).findAll();
        list.addChangeListener(new RealmChangeListener<RealmResults<TaskList>>() {
            @Override
            public void onChange(RealmResults<TaskList> results) {
                updateList(results);
            }
        });
        updateList(list);
    }

    private void updateList(RealmResults<TaskList> results) {
        // Use `findAllAsync` because change listeners are not called when items are deleted and using `findFirst()`
        // See https://github.com/realm/realm-java/issues/3138
        if (results.size() > 0) {
            TaskList element = results.first();
            setTitle(element.getText());
            if (adapter == null) {
                adapter = new TaskAdapter(TaskActivity.this, element.getItems());
                touchHelper = new TouchHelper(new Callback(), adapter);
                touchHelper.attachToRecyclerView(recyclerView);
            }
        } else {
            setTitle(getString(R.string.title_deleted));
        }
    }

    @Override
    protected void onStop() {
        closeRealmAndRecyclerView();
        super.onStop();
    }

    private void closeRealmAndRecyclerView() {
        if (adapter != null) {
            touchHelper.attachToRecyclerView(null);
            adapter = null;
        }
        if (realm != null) {
            realm.removeAllChangeListeners();
            realm.close();
            realm = null;
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_tasks, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch(item.getItemId()) {
            case R.id.action_add:
                if (adapter != null) {
                    adapter.onItemAdded();
                }
                return true;

            case R.id.action_logout:
                Intent intent = new Intent(TaskActivity.this, SignInActivity.class);
                intent.setAction(SignInActivity.ACTION_LOGOUT_EXISTING_USER);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(intent);
                closeRealmAndRecyclerView();
                return true;

            default:
                return super.onOptionsItemSelected(item);
        }
    }

    private class Callback implements TouchHelper.Callback {

        @Override
        public void onMoved(RecyclerView recyclerView, ItemViewHolder from, ItemViewHolder to) {
            final int fromPosition = from.getAdapterPosition();
            final int toPosition = to.getAdapterPosition();
            if (fromPosition == -1) {
                return;
            }
            adapter.onItemMoved(fromPosition, toPosition);
            adapter.notifyItemMoved(fromPosition, toPosition);
        }

        @Override
        public void onCompleted(ItemViewHolder viewHolder) {
            adapter.onItemCompleted(viewHolder.getAdapterPosition());
            adapter.notifyDataSetChanged();
        }

        @Override
        public void onDismissed(ItemViewHolder viewHolder) {
            final int position = viewHolder.getAdapterPosition();
            adapter.onItemDismissed(position);
            adapter.notifyDataSetChanged();
        }

        @Override
        public boolean canDismissed() {
            return true;
        }

        @Override
        public boolean onClicked(ItemViewHolder viewHolder) {
            return false;
        }

        @Override
        public void onChanged(ItemViewHolder viewHolder) {
            adapter.onItemChanged(viewHolder);
            adapter.notifyItemChanged(viewHolder.getAdapterPosition());
        }

        @Override
        public void onAdded() {
            adapter.onItemAdded();
            adapter.notifyItemInserted(0);
        }

        @Override
        public void onReverted() {
            adapter.onItemReverted();
            adapter.notifyDataSetChanged();
        }

        @Override
        public void onExit() {
            closeRealmAndRecyclerView();
            finish();
        }
    }
}
