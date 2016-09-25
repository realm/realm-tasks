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
import android.support.v7.widget.helper.ItemTouchHelper;
import android.util.DisplayMetrics;
import android.view.GestureDetector.SimpleOnGestureListener;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.ViewParent;
import android.view.WindowManager;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.util.ArrayList;
import java.util.List;

import io.realm.realmtasks.R;

import static android.support.v7.widget.RecyclerView.ItemDecoration;
import static android.support.v7.widget.RecyclerView.SCROLL_STATE_DRAGGING;
import static android.support.v7.widget.RecyclerView.State;

public class TouchHelper {

    private static final int POINTER_ID_NONE = -1;

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
    private View overdrawChild;
    private int overdrawChildPosition;
    private List<ViewHolder> swapTargets;
    private List<Integer> distances;
    private TasksOnItemTouchListener.TasksChildDrawingOrderCallback childDrawingOrderCallback;
    private TasksOnItemTouchListener onItemTouchListener;
    private TasksItemDecoration itemDecoration;
    private boolean isAddingCanceled;

    @IntDef({ACTION_STATE_IDLE, ACTION_STATE_SWIPE, ACTION_STATE_DRAG, ACTION_STATE_PULL})
    @Retention(RetentionPolicy.SOURCE)
    private @interface ActionState {
    }

    private static final int ACTION_STATE_IDLE = 0;
    private static final int ACTION_STATE_SWIPE = 1;
    private static final int ACTION_STATE_DRAG = 2;
    private static final int ACTION_STATE_PULL = 3;
    private
    @ActionState
    int actionState = ACTION_STATE_IDLE;

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
        overdrawChildPosition = -1;
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
        void onArchived(ItemViewHolder viewHolder);
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
            overdrawChildPosition = -1;
            if (selected != null) {
                final ItemViewHolder selectedViewHolder = selected;
                final View selectedItemView = selectedViewHolder.itemView;
                if (actionState == ACTION_STATE_SWIPE) {
                    final float translationX = selectedInitialX + dx - selected.itemView.getLeft();
                    final float absDx = Math.abs(translationX);
                    final float maxNiche = logicalDensity * 66;
                    if (absDx < maxNiche) {
                        selectedViewHolder.setIconBarAlpha(absDx / maxNiche);
                        ViewCompat.setTranslationX(selectedViewHolder.getRow(), translationX);
                    } else {
                        selectedViewHolder.setIconBarAlpha(1);
                        if (translationX > 0) {
                            ViewCompat.setTranslationX(selectedViewHolder.getRow(), maxNiche);
                            ViewCompat.setTranslationX(selectedItemView, translationX - maxNiche);
                        } else {
                            ViewCompat.setTranslationX(selectedViewHolder.getRow(), maxNiche * -1);
                            ViewCompat.setTranslationX(selectedItemView, translationX + maxNiche);
                        }
                    }
                } else if (actionState == ACTION_STATE_DRAG) {
                    final float translationY = selectedInitialY + dy - selected.itemView.getTop();
                    ViewCompat.setTranslationY(selectedItemView, translationY);
                } else if (actionState == ACTION_STATE_PULL) {
                    final int height = selected.itemView.getHeight();
                    if (dy >= 0 && dy < height) {
                        float ratio = dy / height;
                        selectedItemView.setTranslationY(height - (height * ratio));
                        float rotationX = 90f - (90f * ratio);
                        selectedItemView.setRotationX(rotationX);
                        if (rotationX < 15) {
                            selectedViewHolder.getText().setText(R.string.release_to_create_item);
                        } else {
                            selectedViewHolder.getText().setText(R.string.pull_to_create_item);
                        }
                    } else {
                        selectedItemView.setTranslationY(0);
                        selectedItemView.setRotationX(0f);
                        if (callback.canDismissed()) {
                            final int actionBaseline = (int) (recyclerView.getHeight() * 0.4);
                            if (dy > actionBaseline + (height * 1) && pullState == PULL_STATE_CANCEL_ADD) {
                                if (!isAddingCanceled) {
                                    TouchHelper.this.selected.itemView.setAlpha(0);
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
                            } else if (dy > actionBaseline) {
                                final float h = dy - actionBaseline;
                                float ratio = h / height;
                                if (ratio > 1) {
                                    ratio = 1;
                                }
                                selected.itemView.setRotationX(ratio * 90);
                                selected.itemView.setTranslationY(height * ratio);
                            }
                            final double revertBaseline = actionBaseline + (height * 0.7);
                            if (pullState == PULL_STATE_ADD && dy > revertBaseline) {
                                pullState = PULL_STATE_CANCEL_ADD;
                            } else if (pullState == PULL_STATE_CANCEL_ADD && dy < revertBaseline) {
                                pullState = PULL_STATE_ADD;
                            }
                        }
                    }
                    int paddingTop = (int) dy - selected.itemView.getHeight();
                    if (paddingTop < 0 - selected.itemView.getHeight()) {
                        paddingTop = 0 - selected.itemView.getHeight();
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
                    if (actionState != ACTION_STATE_PULL) {
                        moveIfNecessary(viewHolder);
                    }
                    TouchHelper.this.recyclerView.invalidate();
                }
            }
        }

        private void moveIfNecessary(ViewHolder fromViewHolder) {
            if (actionState != ACTION_STATE_DRAG) {
                return;
            }
            final int selectedTop = (int) (selectedInitialY + dy);
            if (Math.abs(selectedTop - fromViewHolder.itemView.getTop()) < fromViewHolder.itemView.getHeight() * 0.5) {
                return;
            }
            if (swapTargets == null) {
                swapTargets = new ArrayList<ViewHolder>();
                distances = new ArrayList<Integer>();
            } else {
                swapTargets.clear();
                distances.clear();
            }
            final int selectedBottom = selectedTop + fromViewHolder.itemView.getHeight();
            final int selectedCenterY = (selectedTop + selectedBottom) / 2;
            final RecyclerView.LayoutManager layoutManager = recyclerView.getLayoutManager();
            final int childCount = layoutManager.getChildCount();
            for (int i = 0; i < childCount; i++) {
                final View otherView = layoutManager.getChildAt(i);
                if (otherView == fromViewHolder.itemView || otherView.getBottom() < selectedTop || otherView.getTop() > selectedBottom) {
                    continue;
                }
                final int distance = Math.abs(selectedCenterY - (otherView.getTop() - otherView.getBottom()) / 2);
                int position;
                final int swapTargetsSize = swapTargets.size();
                for (position = 0; position < swapTargetsSize; position++) {
                    if (distance > distances.get(position)) {
                        break;
                    }
                }
                final ViewHolder otherViewHolder = recyclerView.getChildViewHolder(otherView);
                swapTargets.add(position, otherViewHolder);
                distances.add(position, distance);
            }
            final int swapTargetsSize = swapTargets.size();
            if (swapTargetsSize == 0) {
                return;
            }
            int bottom = selectedTop + selected.itemView.getHeight();
            ViewHolder toViewHolder = null;
            int targetScore = -1;
            final int diffY = selectedTop - selected.itemView.getTop();
            for (int i = 0; i < swapTargetsSize; i++) {
                final ViewHolder target = swapTargets.get(i);
                if (diffY < 0) {
                    final int diff = target.itemView.getTop() - selectedTop;
                    if (diff > 0 && target.itemView.getTop() < selected.itemView.getTop()) {
                        final int score = Math.abs(diff);
                        if (score > targetScore) {
                            targetScore = score;
                            toViewHolder = target;
                        }
                    }
                } else {
                    final int diff = target.itemView.getBottom() - bottom;
                    if (diff < 0 && target.itemView.getBottom() > selected.itemView.getBottom()) {
                        final int score = Math.abs(diff);
                        if (score > targetScore) {
                            targetScore = score;
                            toViewHolder = target;
                        }
                    }
                }
            }
            if (toViewHolder == null) {
                swapTargets.clear();
                distances.clear();
                return;
            }
            callback.onMoved(recyclerView, (ItemViewHolder) fromViewHolder, (ItemViewHolder) toViewHolder);
            if (layoutManager instanceof ItemTouchHelper.ViewDropHandler) {
                final ItemTouchHelper.ViewDropHandler viewDropHandler = (ItemTouchHelper.ViewDropHandler) layoutManager;
                viewDropHandler.prepareForDrop(fromViewHolder.itemView, toViewHolder.itemView, 0, selectedTop);
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
                    final float maxNiche = logicalDensity * 66 / 2;
                    final float itemViewTranslationX = TouchHelper.this.selected.itemView.getTranslationX();
                    final float rowTranslationX = TouchHelper.this.selected.getRow().getTranslationX();
                    final float previousTranslationX = itemViewTranslationX + rowTranslationX;
                    TouchHelper.this.selected.reset();
                    if (Math.abs(previousTranslationX) > maxNiche) {
                        if (previousTranslationX < 0) {
                            callback.onDismissed(TouchHelper.this.selected);
                        } else {
                            callback.onArchived(TouchHelper.this.selected);
                        }
                    }
                }
            } else if (previousActionState == ACTION_STATE_DRAG) {
                TouchHelper.this.selected.itemView.setTranslationY(0);
                removeChildDrawingOrder();
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
                if (actionState == ACTION_STATE_DRAG) {
                    setChildDrawingOrder();
                }
            }
            final ViewParent viewParent = recyclerView.getParent();
            viewParent.requestDisallowInterceptTouchEvent(TouchHelper.this.selected != null);
            recyclerView.invalidate();
        }

        private void setChildDrawingOrder() {
            overdrawChild = selected.itemView;
            if (childDrawingOrderCallback == null) {
                childDrawingOrderCallback = new TasksChildDrawingOrderCallback();
                recyclerView.setChildDrawingOrderCallback(childDrawingOrderCallback);
            }
        }

        private void removeChildDrawingOrder() {
            overdrawChild = null;
            if (childDrawingOrderCallback != null) {
                childDrawingOrderCallback = null;
                recyclerView.setChildDrawingOrderCallback(null);
            }
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

            @Override
            public void onLongPress(MotionEvent motionEvent) {
                final int pointerId = motionEvent.getPointerId(0);
                final int pointerIndex = motionEvent.findPointerIndex(pointerId);
                final View childView = findChildView(motionEvent, pointerIndex);
                if (childView == null || pointerId != TouchHelper.this.pointerId) {
                    return;
                }
                final ViewHolder viewHolder = recyclerView.getChildViewHolder(childView);
                if (viewHolder == null) {
                    return;
                }
                initialX = motionEvent.getX(pointerIndex);
                initialY = motionEvent.getY(pointerIndex);
                dx = dy = 0;
                selectView((ItemViewHolder) viewHolder, ACTION_STATE_DRAG);
            }
        }

        private class TasksChildDrawingOrderCallback implements RecyclerView.ChildDrawingOrderCallback {

            @Override
            public int onGetChildDrawingOrder(int childCount, int iteration) {
                if (overdrawChild == null) {
                    return iteration;
                }
                if (overdrawChildPosition == -1) {
                    overdrawChildPosition = recyclerView.indexOfChild(overdrawChild);
                }
                if (childCount - 1 == iteration) {
                    return overdrawChildPosition;
                }
                return iteration < overdrawChildPosition ? iteration : iteration + 1;
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

