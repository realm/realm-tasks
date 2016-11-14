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
import android.graphics.Canvas;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.IntDef;
import android.support.v4.view.GestureDetectorCompat;
import android.support.v4.view.MotionEventCompat;
import android.support.v4.view.ViewCompat;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.RecyclerView.OnItemTouchListener;
import android.support.v7.widget.RecyclerView.ViewHolder;
import android.text.SpannableStringBuilder;
import android.util.DisplayMetrics;
import android.view.GestureDetector.SimpleOnGestureListener;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.ViewParent;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

import io.realm.realmtasks.R;

import static android.support.v7.widget.RecyclerView.ItemDecoration;
import static android.support.v7.widget.RecyclerView.SCROLL_STATE_DRAGGING;
import static android.support.v7.widget.RecyclerView.State;

public class TouchHelper {

    private static final int ANIMATION_DURATION = 150;
    private static final int POINTER_ID_NONE = -1;
    private static final int ADD_THRESHOLD = 46;
    private static final int ICON_WIDTH = 66;

    private final Callback callback;
    private final CommonAdapter adapter;

    private int pointerId = POINTER_ID_NONE;
    private int scaledTouchSlop;
    private float initialX;
    private float initialY;
    private float dx;
    private float dy;
    private float selectedInitialX;
    private float selectedInitialY;
    private float logicalDensity;
    private ItemViewHolder selected;
    private ItemViewHolder currentEditing;
    private RecyclerView recyclerView;
    private TasksOnItemTouchListener onItemTouchListener;
    private TasksItemDecoration itemDecoration;
    private boolean isAddingCanceled;

    @IntDef({ACTION_STATE_IDLE, ACTION_STATE_SWIPE, ACTION_STATE_PULL})
    @Retention(RetentionPolicy.SOURCE)
    private @interface ActionState {
    }

    private static final int ACTION_STATE_IDLE = 0;
    private static final int ACTION_STATE_SWIPE = 1;
    private static final int ACTION_STATE_PULL = 2;
    @ActionState
    private int actionState = ACTION_STATE_IDLE;

    @IntDef({PULL_STATE_ADD, PULL_STATE_CANCEL_ADD})
    @Retention(RetentionPolicy.SOURCE)
    private @interface PullState {
    }

    private static final int PULL_STATE_ADD = 0;
    private static final int PULL_STATE_CANCEL_ADD = 1;
    @PullState
    private int pullState = PULL_STATE_ADD;

    private Handler handler;

    private TouchHelper() {
        this(null, null);
    }

    public TouchHelper(Callback callback, CommonAdapter adapter) {
        this.callback = callback;
        this.adapter = adapter;
        handler = new Handler(Looper.getMainLooper());
    }

    public void attachToRecyclerView(RecyclerView recyclerView) {
        if (this.recyclerView == recyclerView) {
            return;
        }
        if (this.recyclerView != null) {
            destroyCallbacks();
        }
        this.recyclerView = recyclerView;
        if (recyclerView == null) {
            return;
        }
        onItemTouchListener = new TasksOnItemTouchListener(recyclerView.getContext());
        itemDecoration = new TasksItemDecoration();
        recyclerView.setLayoutManager(new LinearLayoutManager(recyclerView.getContext()));
        recyclerView.addOnItemTouchListener(onItemTouchListener);
        recyclerView.addItemDecoration(itemDecoration);
        recyclerView.setAdapter(adapter);
        final Context context = this.recyclerView.getContext();
        final ViewConfiguration viewConfiguration = ViewConfiguration.get(context);
        scaledTouchSlop = viewConfiguration.getScaledTouchSlop();
        DisplayMetrics metrics = new DisplayMetrics();
        final WindowManager systemService = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        systemService.getDefaultDisplay().getMetrics(metrics);
        logicalDensity = metrics.density;
        adapter.setOnFirstItemUpdateListener(new OnFirstItemUpdateListener());
    }

    private void destroyCallbacks() {
        adapter.setOnFirstItemUpdateListener(null);
        recyclerView.setAdapter(null);
        recyclerView.setLayoutManager(null);
        recyclerView.removeItemDecoration(itemDecoration);
        recyclerView.removeOnItemTouchListener(onItemTouchListener);
        onItemTouchListener = null;
        itemDecoration = null;
    }

    public interface Callback {

        void onMoved(RecyclerView recyclerView, ItemViewHolder from, ItemViewHolder to);
        void onCompleted(ItemViewHolder viewHolder);
        void onDismissed(ItemViewHolder viewHolder);
        boolean canDismissed();
        boolean onClicked(ItemViewHolder viewHolder);
        void onChanged(ItemViewHolder viewHolder);
        void onAdded();
        void onReverted(boolean shouldUpdateUI);
        void onExit();
    }

    private class TasksItemDecoration extends ItemDecoration {

        @Override
        public void onDraw(Canvas c, RecyclerView parent, State state) {
            if (selected != null) {
                final ItemViewHolder selectedViewHolder = selected;
                final View selectedItemView = selectedViewHolder.itemView;
                final int height = selectedItemView.getHeight();
                if (actionState == ACTION_STATE_SWIPE) {
                    final float translationX = selectedInitialX + dx - selectedItemView.getLeft();
                    final float absDx = Math.abs(translationX);
                    final float maxNiche = logicalDensity * ICON_WIDTH;
                    if (absDx < maxNiche) {
                        selectedViewHolder.setIconBarAlpha(absDx / maxNiche);
                        ViewCompat.setTranslationX(selectedViewHolder.getRow(), translationX);
                        if (translationX > 0) {
                            selectedViewHolder.setStrikeThroughRatio(absDx / maxNiche);
                            selectedViewHolder.revertBackgroundColorIfNeeded();
                        }
                    } else {
                        selectedViewHolder.setIconBarAlpha(1);
                        if (translationX > 0) {
                            ViewCompat.setTranslationX(selectedViewHolder.getRow(), maxNiche);
                            ViewCompat.setTranslationX(selectedItemView, translationX - maxNiche);
                            selectedViewHolder.setStrikeThroughRatio(1f);
                            selectedViewHolder.changeBackgroundColorIfNeeded();
                        } else {
                            ViewCompat.setTranslationX(selectedViewHolder.getRow(), maxNiche * -1);
                            ViewCompat.setTranslationX(selectedItemView, translationX + maxNiche);
                        }
                    }
                } else if (actionState == ACTION_STATE_PULL) {
                    boolean hintPanelVisible = false;
                    if (dy >= 0 && dy < height) {
                        selectedViewHolder.getText().setText(R.string.pull_to_create_item);
                        double ratio = dy / height;
                        float rotationX = (float) (90 - Math.toDegrees(Math.asin(ratio)));
                        selectedItemView.setRotationX(rotationX);
                        selectedItemView.setPivotY(height);
                    } else {
                        selectedViewHolder.getText().setText(R.string.release_to_create_item);
                        selectedItemView.setTranslationY(0);
                        selectedItemView.setRotationX(0f);
                        if (callback.canDismissed()) {
                            final int actionBaseline = height * 2;
                            if (dy > actionBaseline) {
                                hintPanelVisible = true;
                            }
                            if (pullState == PULL_STATE_ADD && dy > actionBaseline) {
                                pullState = PULL_STATE_CANCEL_ADD;
                            } else if (pullState == PULL_STATE_CANCEL_ADD && dy < actionBaseline) {
                                pullState = PULL_STATE_ADD;
                            }
                        }
                    }
                    selected.setHintPanelVisible(hintPanelVisible);
                    int paddingTop = (int) dy - height;
                    if (paddingTop < 0 - height) {
                        paddingTop = 0 - height;
                    }
                    ViewCompat.setPaddingRelative(recyclerView, 0, paddingTop, 0, 0);
                    recyclerView.scrollToPosition(0);
                }
            }
            if (actionState == ACTION_STATE_PULL && selected == null) {
                recyclerView.scrollBy(0, (int) dy * -1);
            }
        }
    }

    private class TasksOnItemTouchListener implements OnItemTouchListener {

        private GestureDetectorCompat gestureDetector;

        public TasksOnItemTouchListener(Context context) {
            gestureDetector = new GestureDetectorCompat(context, new TasksSimpleOnGestureListener());
        }

        @Override
        public boolean onInterceptTouchEvent(RecyclerView rv, MotionEvent motionEvent) {
            gestureDetector.onTouchEvent(motionEvent);
            final int action = MotionEventCompat.getActionMasked(motionEvent);
            if (action == MotionEvent.ACTION_DOWN) {
                pointerId = motionEvent.getPointerId(0);
                final int pointerIndex = motionEvent.findPointerIndex(pointerId);
                initialX = motionEvent.getX(pointerIndex);
                initialY = motionEvent.getY(pointerIndex);
                isAddingCanceled = false;
            } else if (action == MotionEvent.ACTION_CANCEL || action == MotionEvent.ACTION_UP) {
                pointerId = POINTER_ID_NONE;
                selectView(null, ACTION_STATE_IDLE);
            } else if (pointerId != POINTER_ID_NONE) {
                final int pointerIndex = motionEvent.findPointerIndex(pointerId);
                if (pointerIndex != -1) {
                    prepareSwipe(motionEvent);
                    if (preparePull(motionEvent)) {
                        return true;
                    }
                }
            }
            boolean shouldDisableIntercept = selected != null;
            return shouldDisableIntercept;
        }

        @Override
        public void onTouchEvent(RecyclerView recyclerView, MotionEvent motionEvent) {
            gestureDetector.onTouchEvent(motionEvent);
            if (pointerId == POINTER_ID_NONE) {
                return;
            }
            pointerId = motionEvent.getPointerId(0);
            final int pointerIndex = motionEvent.findPointerIndex(pointerId);
            if (pointerIndex != -1) {
                prepareSwipe(motionEvent);
                preparePull(motionEvent);
            }
            final ViewHolder viewHolder = selected;
            final int action = MotionEventCompat.getActionMasked(motionEvent);

            if (action == MotionEvent.ACTION_CANCEL || action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) {
                pointerId = POINTER_ID_NONE;
                selectView(null, ACTION_STATE_IDLE);
            } else if (action == MotionEvent.ACTION_MOVE) {
                if (actionState == ACTION_STATE_PULL || viewHolder != null) {
                    dx = motionEvent.getX(pointerIndex) - initialX;
                    dy = motionEvent.getY(pointerIndex) - initialY;
                    TouchHelper.this.recyclerView.invalidate();
                }
            }
        }

        @Override
        public void onRequestDisallowInterceptTouchEvent(boolean disallowIntercept) {
            if (!disallowIntercept) {
                return;
            }
            selectView(null, ACTION_STATE_IDLE);
        }

        private boolean checkHit(View view, float x, float y, float left, float top) {
            return x >= left && y >= top && x <= left + view.getWidth() && y <= top + view.getHeight();
        }

        private View findChildView(MotionEvent motionEvent, int pointerIndex) {
            final float x = motionEvent.getX(pointerIndex);
            final float y = motionEvent.getY(pointerIndex);
            if (selected != null) {
                final View selectedView = selected.itemView;
                if (checkHit(selectedView, x, y, selectedInitialX + dx, selectedInitialY + dy)) {
                    return selectedView;
                }
            }
            return recyclerView.findChildViewUnder(x, y);
        }

        private boolean preparePull(MotionEvent motionEvent) {
            if (actionState != ACTION_STATE_IDLE) {
                return false;
            }
            final View firstChild = recyclerView.getChildAt(0);
            final int firstVisiblePosition = recyclerView.getChildAdapterPosition(firstChild);
            if (firstChild == null || (firstVisiblePosition == 0 && firstChild.getTop() == 0)) {
                final int pointerIndex = motionEvent.findPointerIndex(pointerId);
                final int action = MotionEventCompat.getActionMasked(motionEvent);
                if (action == MotionEvent.ACTION_MOVE) {
                    dy = motionEvent.getY(pointerIndex) - initialY;
                    if (dy > 10) {
                        initialY = motionEvent.getY(pointerIndex);
                        callback.onAdded();
                        pullState = PULL_STATE_ADD;
                        selectView(null, ACTION_STATE_PULL);
                        return true;
                    }
                }
            }
            return false;
        }

        private void prepareSwipe(MotionEvent motionEvent) {
            if (selected != null || recyclerView.getScrollState() == SCROLL_STATE_DRAGGING || pointerId == POINTER_ID_NONE) {
                return;
            }
            final int action = MotionEventCompat.getActionMasked(motionEvent);
            if (action != MotionEvent.ACTION_MOVE) {
                return;
            }
            final int pointerIndex = motionEvent.findPointerIndex(pointerId);
            dx = motionEvent.getX(pointerIndex) - initialX;
            dy = motionEvent.getY(pointerIndex) - initialY;
            final float absDx = Math.abs(dx);
            final float absDy = Math.abs(dy);

            if ((absDx < scaledTouchSlop && absDy < scaledTouchSlop) || absDy > absDx) {
                return;
            }
            final View childView = findChildView(motionEvent, pointerIndex);
            if (childView == null) {
                return;
            }
            final ViewHolder childViewHolder = recyclerView.getChildViewHolder(childView);
            if (childViewHolder == null) {
                return;
            }
            if (currentEditing == childViewHolder) {
                return;
            }
            TouchHelper.this.dx = TouchHelper.this.dy = 0;
            selectView((ItemViewHolder) childViewHolder, ACTION_STATE_SWIPE);
        }

        private void selectView(ItemViewHolder selected, @ActionState int actionState) {
            if (selected == TouchHelper.this.selected && actionState == TouchHelper.this.actionState) {
                return;
            }
            final @ActionState int previousActionState = TouchHelper.this.actionState;
            if (previousActionState == ACTION_STATE_SWIPE) {
                if (TouchHelper.this.selected != null) {
                    final float maxNiche = logicalDensity * ICON_WIDTH;
                    final View selectedItemView = TouchHelper.this.selected.itemView;
                    final float itemViewTranslationX = selectedItemView.getTranslationX();
                    final float rowTranslationX = TouchHelper.this.selected.getRow().getTranslationX();
                    final float previousTranslationX = itemViewTranslationX + rowTranslationX;
                    boolean completed = TouchHelper.this.selected.getCompleted();
                    TouchHelper.this.selected.reset();
                    TouchHelper.this.selected.setCompleted(completed);
                    if (Math.abs(previousTranslationX) > maxNiche) {
                        if (previousTranslationX < 0) {
                            animateDismissItem(selectedItemView, previousTranslationX);
                        } else {
                            animateCompleteItem(selectedItemView, previousTranslationX);
                        }
                    } else {
                        final CharSequence text = TouchHelper.this.selected.getText().getText();
                        final SpannableStringBuilder stringBuilder = new SpannableStringBuilder(text, 0, text.length());
                        stringBuilder.clearSpans();
                        TouchHelper.this.selected.getText().setText(stringBuilder);
                    }
                }
            } else if (previousActionState == ACTION_STATE_PULL) {
                ViewCompat.setPaddingRelative(recyclerView, 0, 0, 0, 0);
                if (TouchHelper.this.selected != null) {
                    TouchHelper.this.selected.itemView.setRotationX(0);
                    TouchHelper.this.selected.itemView.setTranslationY(0);
                    if (pullState == PULL_STATE_CANCEL_ADD) {
                        TouchHelper.this.selected.itemView.setAlpha(0);
                        if (!isAddingCanceled) {
                            callback.onReverted(false);
                            isAddingCanceled = true;
                        }
                        recyclerView.setVisibility(View.INVISIBLE);
                        handler.post(new Runnable() {
                            @Override
                            public void run() {
                                callback.onExit();
                            }
                        });
                    } else if (dy < logicalDensity * ADD_THRESHOLD) {
                        callback.onReverted(false);
                    } else {
                        TouchHelper.this.selected.itemView.setAlpha(1f);
                        TouchHelper.this.selected.getText().setText("");
                        currentEditing = TouchHelper.this.selected;
                        TouchHelper.this.selected.setEditable(true);
                    }
                    TouchHelper.this.selected = null;
                }
            }
            TouchHelper.this.selected = selected;
            TouchHelper.this.actionState = actionState;
            if (selected != null) {
                selectedInitialX = selected.itemView.getLeft();
                selectedInitialY = selected.itemView.getTop();
            }
            final ViewParent viewParent = recyclerView.getParent();
            viewParent.requestDisallowInterceptTouchEvent(TouchHelper.this.selected != null);
            recyclerView.invalidate();
        }

        private void animateDismissItem(View selectedItemView, float translationX) {
            final TranslateAnimation translateAnimation =
                    new TranslateAnimation(translationX, 0 - selectedItemView.getWidth(), 0, 0);
            translateAnimation.setDuration(ANIMATION_DURATION);
            translateAnimation.setAnimationListener(new DismissAnimationListener(TouchHelper.this.selected));
            ViewCompat.setHasTransientState(selectedItemView, true);
            selectedItemView.startAnimation(translateAnimation);
        }

        private void animateCompleteItem(View selectedItemView, float translationX) {
            final TranslateAnimation translateAnimation =
                    new TranslateAnimation(translationX, 0, 0, 0);
            translateAnimation.setDuration(ANIMATION_DURATION);
            translateAnimation.setAnimationListener(new CompleteAnimationListener(TouchHelper.this.selected));
            ViewCompat.setHasTransientState(selectedItemView, true);
            selectedItemView.startAnimation(translateAnimation);
        }

        private class TasksSimpleOnGestureListener extends SimpleOnGestureListener {

            @Override
            public boolean onDown(MotionEvent motionEvent) {
                return true;
            }

            @Override
            public boolean onSingleTapConfirmed(MotionEvent motionEvent) {
                final int pointerId = motionEvent.getPointerId(0);
                final int pointerIndex = motionEvent.findPointerIndex(pointerId);
                final View childView = findChildView(motionEvent, pointerIndex);
                if (childView == null) {
                    if (currentEditing != null) {
                        doEndOfEditing();
                    }
                    return false;
                }
                final ItemViewHolder viewHolder = (ItemViewHolder) recyclerView.getChildViewHolder(childView);
                if (viewHolder == null) {
                    doEndOfEditing();
                    return false;
                }
                if (currentEditing == viewHolder) {
                    if (motionEvent.getX() < viewHolder.itemView.getWidth() / 2) {
                        return false;
                    } else {
                        doEndOfEditing();
                        return false;
                    }
                }
                if (currentEditing != null) {
                    doEndOfEditing();
                    return false;
                }
                if (motionEvent.getX() > viewHolder.itemView.getWidth() - viewHolder.getBadge().getWidth()) {
                    if (callback.onClicked(viewHolder)) {
                        return true;
                    }
                }
                currentEditing = viewHolder;
                viewHolder.setEditable(true);
                return true;
            }

            private void doEndOfEditing() {
                currentEditing.setEditable(false);
                callback.onChanged(currentEditing);
                currentEditing = null;
            }
        }

        private class DismissAnimationListener implements Animation.AnimationListener {
            private final ItemViewHolder itemViewHolder;

            public DismissAnimationListener(ItemViewHolder itemViewHolder) {
                this.itemViewHolder = itemViewHolder;
            }

            @Override
            public void onAnimationStart(Animation animation) {
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                callback.onDismissed(itemViewHolder);
                ViewCompat.setHasTransientState(itemViewHolder.itemView, false);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        }

        private class CompleteAnimationListener implements Animation.AnimationListener {
            private final ItemViewHolder itemViewHolder;

            public CompleteAnimationListener(ItemViewHolder itemViewHolder) {
                this.itemViewHolder = itemViewHolder;
            }

            @Override
            public void onAnimationStart(Animation animation) {
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                callback.onCompleted(itemViewHolder);
                ViewCompat.setHasTransientState(itemViewHolder.itemView, false);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {
            }
        }
    }

    private class OnFirstItemUpdateListener implements CommonAdapter.OnFirstItemUpdateListener {

        @Override
        public void updated(ViewHolder viewHolder) {
            if (actionState == ACTION_STATE_PULL) {
                selected = (ItemViewHolder) viewHolder;
            }
        }
    }
}

