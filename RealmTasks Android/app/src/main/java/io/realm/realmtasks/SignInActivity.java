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

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.EditorInfo;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import io.realm.Credentials;
import io.realm.ObjectServerError;
import io.realm.User;

public class SignInActivity extends AppCompatActivity {

    public static final String ACTION_LOGOUT_EXISTING_USER = "action.logoutExistingUser";

    private AutoCompleteTextView usernameView;
    private EditText passwordView;
    private View progressView;
    private View loginFormView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sign_in);
        usernameView = (AutoCompleteTextView) findViewById(R.id.username);
        passwordView = (EditText) findViewById(R.id.password);
        passwordView.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView textView, int id, KeyEvent keyEvent) {
                if (id == R.id.log_in || id == EditorInfo.IME_NULL) {
                    attemptLogin();
                    return true;
                }
                return false;
            }
        });

        final Button signInButton = (Button) findViewById(R.id.sign_in_button);
        signInButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                attemptLogin();
            }
        });

        loginFormView = findViewById(R.id.sign_in_form);
        progressView = findViewById(R.id.sign_in_progress);

        // Check if we already got a user, if yes, just continue automatically
        if (savedInstanceState == null && User.currentUser() != null) {
            if (ACTION_LOGOUT_EXISTING_USER.equals(getIntent().getAction())) {
                User.currentUser().logout();
            } else {
                loginComplete(User.currentUser());
            }
        }
    }

    private void loginComplete(User user) {
        UserManager.setActiveUser(user);
        Intent listActivity = new Intent(this, TaskListActivity.class);
        Intent tasksActivity = new Intent(this, TaskActivity.class);
        tasksActivity.putExtra(TaskActivity.EXTRA_LIST_ID, RealmTasksApplication.DEFAULT_LIST_ID);
        startActivities(new Intent[] { listActivity, tasksActivity} );
        finish();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        final MenuInflater menuInflater = getMenuInflater();
        menuInflater.inflate(R.menu.menu_signin, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        final int itemId = item.getItemId();
        if (itemId == R.id.register) {
            startActivity(new Intent(this, RegisterActivity.class));
        }
        return super.onOptionsItemSelected(item);
    }

    private void attemptLogin() {
        usernameView.setError(null);
        passwordView.setError(null);

        final String email = usernameView.getText().toString();
        final String password = passwordView.getText().toString();

        boolean cancel = false;
        View focusView = null;

        if (TextUtils.isEmpty(password)) {
            passwordView.setError(getString(R.string.error_invalid_password));
            focusView = passwordView;
            cancel = true;
        }

        if (TextUtils.isEmpty(email)) {
            usernameView.setError(getString(R.string.error_field_required));
            focusView = usernameView;
            cancel = true;
        }

        if (cancel) {
            focusView.requestFocus();
        } else {
            showProgress(true);
            User.loginAsync(Credentials.usernamePassword(email, password, false), RealmTasksApplication.AUTH_URL, new User.Callback() {
                        @Override
                        public void onSuccess(User user) {
                            showProgress(false);
                            loginComplete(user);
                        }

                        @Override
                        public void onError(ObjectServerError error) {
                            showProgress(false);
                            String errorMsg;
                            switch (error.getErrorCode()) {
                                case UNKNOWN_ACCOUNT:
                                    errorMsg = "Account does not exists.";
                                    break;
                                case INVALID_CREDENTIALS:
                                    errorMsg = "User name and password does not match";
                                    break;
                                default:
                                    errorMsg = error.toString();
                            }
                            Toast.makeText(SignInActivity.this, errorMsg, Toast.LENGTH_LONG).show();
                        }
                    });
        }
    }

    private void showProgress(final boolean show) {
        final int shortAnimTime = getResources().getInteger(android.R.integer.config_shortAnimTime);

        loginFormView.setVisibility(show ? View.GONE : View.VISIBLE);
        loginFormView.animate().setDuration(shortAnimTime).alpha(
                show ? 0 : 1).setListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                loginFormView.setVisibility(show ? View.GONE : View.VISIBLE);
            }
        });

        progressView.setVisibility(show ? View.VISIBLE : View.GONE);
        progressView.animate().setDuration(shortAnimTime).alpha(
                show ? 1 : 0).setListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                progressView.setVisibility(show ? View.VISIBLE : View.GONE);
            }
        });
    }
}

