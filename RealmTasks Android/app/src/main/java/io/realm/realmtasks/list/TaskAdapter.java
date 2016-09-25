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

package io.realm.realmtasks.list;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;

import io.realm.OrderedRealmCollection;
import io.realm.Realm;
import io.realm.RealmList;
import io.realm.realmtasks.model.Task;

public class TaskAdapter extends CommonAdapter<Task> implements TouchHelperAdapter {

    public TaskAdapter(Context context, OrderedRealmCollection<Task> items) {
        super(context, items);
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
        super.onBindViewHolder(holder, position);
        final ItemViewHolder itemViewHolder = (ItemViewHolder) holder;
        final Task task = items.get(position);
        if (task.isValid()) {
            final TextView text = itemViewHolder.getText();
            text.setText(task.getText());
            narrowRightMargin(text);
            narrowRightMargin(itemViewHolder.getEditText());
            itemViewHolder.setCompleted(task.isCompleted());
        }
    }

    private void narrowRightMargin(View view) {
        final RelativeLayout.LayoutParams layoutParams = (RelativeLayout.LayoutParams) view.getLayoutParams();
        layoutParams.rightMargin = (int) (layoutParams.rightMargin * 0.2);
    }

    @Override
    public void onItemAdded() {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm realm) {
                final Task task = realm.createObject(Task.class);
                task.setText("New task");
                items.add(0, task);
            }
        });
        realm.close();
    }

    @Override
    public void onItemMoved(final int fromPosition, final int toPosition) {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm realm) {
                moveItems(fromPosition, toPosition);
            }
        });
        realm.close();
    }

    @Override
    public void onItemArchived(final int position) {
        final Task task = items.get(position);
        final Realm realm = Realm.getDefaultInstance();
        final int count = (int) ((RealmList<Task>) items).where().equalTo(Task.FIELD_COMPLETED, false).count();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm realm) {
                if (!task.isCompleted()) {
                    task.setCompleted(true);
                    moveItems(position, count - 1);
                } else {
                    task.setCompleted(false);
                    moveItems(position, count);
                }
            }
        });
        realm.close();
    }

    @Override
    public void onItemDismissed(final int position) {
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm realm) {
                items.remove(position);
            }
        });
        realm.close();
    }

    @Override
    public void onItemReverted() {
        if (items.size() == 0) {
            return;
        }
        final Realm realm = Realm.getDefaultInstance();
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm realm) {
                items.remove(0);
            }
        });
        realm.close();
    }

    @Override
    public int generatedRowColor(int row) {
        return ItemViewHolder.ColorHelper.getColor(ItemViewHolder.ColorHelper.taskColors, row, getItemCount());
    }

    @Override
    public void onItemChanged(final ItemViewHolder viewHolder) {
        final Realm realm = Realm.getDefaultInstance();
        final int position = viewHolder.getAdapterPosition();
        if (position < 0) {
            return;
        }
        realm.executeTransaction(new Realm.Transaction() {
            @Override
            public void execute(Realm realm) {
                Task task = items.get(position);
                task.setText(viewHolder.getText().getText().toString());
            }
        });
        realm.close();
    }
}
