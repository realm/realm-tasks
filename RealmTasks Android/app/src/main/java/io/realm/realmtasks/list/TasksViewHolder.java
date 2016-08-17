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
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.util.Random;

import io.realm.realmtasks.R;

public class TasksViewHolder extends RecyclerView.ViewHolder {
    private final RelativeLayout iconBar;
    private final RelativeLayout row;
    private final TextView text;

    public TasksViewHolder(View itemView) {
        super(itemView);
        iconBar = (RelativeLayout) itemView.findViewById(R.id.icon_bar);
        row = (RelativeLayout) itemView.findViewById(R.id.row);
        row.setBackgroundColor(generateBackgroundColor());
        text = (TextView) row.findViewById(R.id.text);
    }

    private int generateBackgroundColor() {
        final int color = new Random().nextInt();
        final int colorMask = 0xFFFFFF;
        final int alpha = 0xFF000000;
        return alpha | (color & colorMask);
    }

    public void resetPositionsAndAlpha() {
        itemView.setTranslationX(0);
        itemView.setTranslationY(0);
        itemView.setRotationX(0);
        itemView.setAlpha(1f);
        row.setTranslationX(0);
        setIconBarAlpha(1f);
    }

    public void resetBackgroundColor() {
        row.setBackgroundColor(generateBackgroundColor());
    }

    public RelativeLayout getRow() {
        return row;
    }

    public TextView getText() {
        return text;
    }

    public void setIconBarAlpha(float alpha) {
        iconBar.setAlpha(alpha);
    }
}
