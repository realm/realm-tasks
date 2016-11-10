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
import android.graphics.Paint;
import android.support.annotation.ColorInt;
import android.support.v4.content.ContextCompat;
import android.support.v7.widget.RecyclerView;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.CharacterStyle;
import android.text.style.ForegroundColorSpan;
import android.text.style.StrikethroughSpan;
import android.view.View;
import android.view.animation.AlphaAnimation;
import android.view.animation.RotateAnimation;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import io.realm.realmtasks.R;

public class ItemViewHolder extends RecyclerView.ViewHolder {

    @ColorInt
    private final int cellUnusedColor;
    @ColorInt
    private final int cellCompletedColor;
    @ColorInt
    private final int cellCompletedBackgroundColor;
    @ColorInt
    private final int cellDefaultColor;

    private final RelativeLayout iconBar;
    private final RelativeLayout row;
    private final RelativeLayout hintPanel;
    private final ImageView arrow;
    private final EditText editText;
    private final TextView badge;
    private final TextView text;
    private final RecyclerView.Adapter adapter;
    private boolean completed;
    private boolean shouldChangeBackgroundColor;
    private boolean shouldChangeTextColor;
    private double previousFirstLength;

    public ItemViewHolder(View itemView, RecyclerView.Adapter adapter) {
        super(itemView);
        iconBar = (RelativeLayout) itemView.findViewById(R.id.icon_bar);
        row = (RelativeLayout) itemView.findViewById(R.id.row);
        hintPanel = (RelativeLayout) itemView.findViewById(R.id.hint_panel);
        arrow = (ImageView) hintPanel.findViewById(R.id.arrow);
        badge = (TextView) row.findViewById(R.id.badge);
        text = (TextView) row.findViewById(R.id.text);
        editText = (EditText) row.findViewById(R.id.edit_text);
        cellUnusedColor = ContextCompat.getColor(itemView.getContext(), R.color.cell_unused_color);
        cellCompletedColor = ContextCompat.getColor(itemView.getContext(), R.color.cell_completed_color);
        cellCompletedBackgroundColor = ContextCompat.getColor(itemView.getContext(), R.color.cell_completed_background_color);
        cellDefaultColor = ContextCompat.getColor(itemView.getContext(), R.color.cell_default_color);
        shouldChangeBackgroundColor = true;
        shouldChangeTextColor = true;
        previousFirstLength = -1;
        this.adapter = adapter;
    }

    private int generateBackgroundColor() {
        if (adapter != null && adapter instanceof TouchHelperAdapter) {
            return ((TouchHelperAdapter) adapter).generatedRowColor(getAdapterPosition());
        } else {
            return cellUnusedColor;
        }
    }

    public void setCompleted(boolean completed) {
        if (completed == this.completed && !shouldChangeTextColor) {
            return;
        }
        this.completed = completed;
        int paintFlags = text.getPaintFlags();
        if (completed) {
            text.setTextColor(cellCompletedColor);
            text.setPaintFlags(paintFlags | Paint.STRIKE_THRU_TEXT_FLAG);
            row.setBackgroundColor(
                    cellCompletedBackgroundColor);
        } else {
            if (badge.getVisibility() == View.VISIBLE && badge.getText().equals("0")) {
                text.setTextColor(cellCompletedColor);
            } else {
                text.setTextColor(cellDefaultColor);
            }
            text.setPaintFlags(paintFlags & ~Paint.STRIKE_THRU_TEXT_FLAG);
            row.setBackgroundColor(generateBackgroundColor());
        }
        shouldChangeTextColor = false;
    }

    public boolean getCompleted() {
        return completed;
    }

    public void setEditable(boolean set) {
        if (set) {
            if (isEditable() == false) {
                editText.setText(text.getText().toString());
            }
            text.setVisibility(View.GONE);
            editText.setVisibility(View.VISIBLE);
            editText.requestFocus();
            final Context context = editText.getContext();
            final InputMethodManager inputMethodManager =
                    (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
            inputMethodManager.showSoftInput(editText, InputMethodManager.SHOW_IMPLICIT);

        } else {
            if (isEditable() == true) {
                text.setText(editText.getText().toString());
            }
            text.setVisibility(View.VISIBLE);
            editText.setVisibility(View.GONE);
        }
    }

    public boolean isEditable() {
        return editText.getVisibility() == View.VISIBLE;
    }

    public void setBadgeVisible(boolean visible) {
        if (visible) {
            badge.setVisibility(View.VISIBLE);
        } else {
            badge.setVisibility(View.GONE);
        }
        shouldChangeTextColor = true;
    }

    public void setBadgeCount(int count) {
        badge.setText(Integer.toString(count));
        if (count == 0) {
            text.setTextColor(cellCompletedColor);
            badge.setTextColor(cellCompletedColor);
        } else {
            text.setTextColor(cellDefaultColor);
            badge.setTextColor(cellDefaultColor);
        }
        shouldChangeTextColor = true;
    }

    public void setHintPanelVisible(boolean visible) {
        final int visibility = hintPanel.getVisibility();
        boolean previousVisible = visibility == View.VISIBLE;
        if (previousVisible == visible) {
            return;
        }
        if (visible) {
            hintPanel.setVisibility(View.VISIBLE);
            final AlphaAnimation alphaAnimation = new AlphaAnimation(0.2f, 1.0f);
            alphaAnimation.setDuration(150);
            hintPanel.setAnimation(alphaAnimation);
            final RotateAnimation rotateAnimation = new RotateAnimation(
                    -90, 0, RotateAnimation.RELATIVE_TO_SELF, 0.5f, RotateAnimation.RELATIVE_TO_SELF, 0.5f);
            rotateAnimation.setDuration(500);
            arrow.startAnimation(rotateAnimation);
        } else {
            hintPanel.setVisibility(View.GONE);
        }
    }

    public void reset() {
        text.setVisibility(View.VISIBLE);
        editText.setVisibility(View.GONE);
        itemView.setTranslationX(0);
        itemView.setTranslationY(0);
        itemView.setRotationX(0);
        itemView.setAlpha(1f);
        row.setTranslationX(0);
        setIconBarAlpha(1f);
        setCompleted(false);
        setHintPanelVisible(false);
        shouldChangeBackgroundColor = true;
        shouldChangeTextColor = true;
        previousFirstLength = -1;
    }

    public void resetBackgroundColor() {
        row.setBackgroundColor(generateBackgroundColor());
    }

    public RelativeLayout getRow() {
        return row;
    }

    public TextView getBadge() {
        return badge;
    }

    public TextView getText() {
        return text;
    }

    public EditText getEditText() {
        return editText;
    }

    public void setIconBarAlpha(float alpha) {
        iconBar.setAlpha(alpha);
    }

    public void changeBackgroundColorIfNeeded() {
        if (!shouldChangeBackgroundColor) {
            return;
        }
        if (completed) {
            row.setBackgroundColor(generateBackgroundColor());
        } else {
            row.setBackgroundColor(ContextCompat.getColor(itemView.getContext(), R.color.completing));
        }
        shouldChangeBackgroundColor = false;
    }

    public void revertBackgroundColorIfNeeded() {
        if (shouldChangeBackgroundColor) {
            return;
        }
        row.setBackgroundColor(generateBackgroundColor());
        shouldChangeBackgroundColor = true;
    }

    public void setStrikeThroughRatio(float strikeThroughRatio) {
        final CharSequence text = this.text.getText();
        final int textLength = text.length();
        int firstLength = (int) (textLength * strikeThroughRatio);
        if (firstLength > textLength) {
            firstLength = textLength;
        } else if (firstLength == textLength - 1) {
            firstLength = textLength;
        }
        if (firstLength == previousFirstLength) {
            return;
        }
        previousFirstLength = firstLength;
        final int appendedLength = textLength - firstLength;
        final SpannableStringBuilder stringBuilder = new SpannableStringBuilder(text, 0, textLength);
        stringBuilder.clearSpans();
        this.text.setPaintFlags(this.text.getPaintFlags() & ~Paint.STRIKE_THRU_TEXT_FLAG);
        final CharacterStyle firstCharStyle, secondCharStyle;
        if (completed) {
            firstCharStyle = new ForegroundColorSpan(cellCompletedColor);
            secondCharStyle = new StrikethroughSpan();
        } else {
            firstCharStyle = new StrikethroughSpan();
            secondCharStyle = new ForegroundColorSpan(cellDefaultColor);
        }
        stringBuilder.setSpan(firstCharStyle, 0, firstLength, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        stringBuilder.setSpan(secondCharStyle, textLength - appendedLength, textLength, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        this.text.setText(stringBuilder);
    }

    public static class ColorHelper {

        public static final int[] taskColors= {
                0xFFE7A776,
                0xFFE47D72,
                0xFFE9636F,
                0xFFF25191,
                0xFF9A50A4,
                0xFF58569D,
                0xFF38477E
        };

        public static final int[] listColors = {
                0xFF0693FB,
                0xFF109EFB,
                0xFF1AA9FB,
                0xFF21B4FB,
                0xFF28BEFB,
                0xFF2EC6FB,
                0xFF36CFFB
        };

        public static int getColor(int[] targetColors, int index, int size) {
            if (size < 13) {
                size = 13;
            }
            if (index < 0) {
                index = 0;
            } else if (index >= size) {
                index = size - 1;
            }
            double fraction = (double) index / size;
            if (fraction < 0.0) {
                fraction = 0.0;
            } else if (fraction > 1.0) {
                fraction = 1.0;
            }
            final double step = 1.0 / (targetColors.length - 1);
            final int colorIndex = (int) (fraction / step);
            final int topColor = targetColors[colorIndex];
            final int bottomColor = targetColors[colorIndex + 1];
            final int topRed = (topColor >> 16) & 0xFF;
            final int bottomRed = (bottomColor >> 16) & 0xFF;
            final int topGreen = (topColor >> 8) & 0xFF;
            final int bottomGreen = (bottomColor >> 8) & 0xFF;
            final int topBlue = topColor & 0xFF;
            final int bottomBlue = bottomColor & 0xFF;
            final double colorOffset = (fraction - (colorIndex * step)) / step;
            final int red = (int) (topRed + (bottomRed - topRed) * colorOffset);
            final int green = (int) (topGreen + (bottomGreen - topGreen) * colorOffset);
            final int blue = (int) (topBlue + (bottomBlue - topBlue) * colorOffset);
            final int color = 0xFF000000 | (red << 16) | (green << 8) | blue;
            return color;
        }
    }
}
