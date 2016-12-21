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
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.Collections;

import io.realm.OrderedRealmCollection;
import io.realm.RealmModel;
import io.realm.RealmRecyclerViewAdapter;
import io.realm.realmtasks.R;

public class CommonAdapter<T extends RealmModel> extends RealmRecyclerViewAdapter<T, RecyclerView.ViewHolder> {

    protected OnFirstItemUpdateListener onFirstItemUpdateListener;

    public CommonAdapter(Context context, OrderedRealmCollection<T> items) {
        super(context, items, false);
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View rowItem = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_row, parent, false);
        return new ItemViewHolder(rowItem, this);
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
        final ItemViewHolder itemViewHolder = (ItemViewHolder) holder;
        itemViewHolder.reset();
        itemViewHolder.resetBackgroundColor();
        if (onFirstItemUpdateListener != null && position == 0) {
            onFirstItemUpdateListener.updated(holder);
        }
    }

    protected void moveItems(int fromPosition, int toPosition) {
        if (fromPosition < toPosition) {
            for (int i = fromPosition; i < toPosition; i++) {
                Collections.swap(getData(), i, i + 1);
            }
        } else {
            for (int i = fromPosition; i > toPosition; i--) {
                Collections.swap(getData(), i, i - 1);
            }
        }
    }

    public void setOnFirstItemUpdateListener(OnFirstItemUpdateListener onFirstItemUpdateListener) {
        this.onFirstItemUpdateListener = onFirstItemUpdateListener;
    }

    public interface OnFirstItemUpdateListener {

        void updated(RecyclerView.ViewHolder viewHolder);
    }
}
