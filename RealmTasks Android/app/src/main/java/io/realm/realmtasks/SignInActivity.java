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

import com.facebook.login.LoginResult;
import com.facebook.login.widget.LoginButton;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.common.SignInButton;

import io.realm.SyncCredentials;
import io.realm.ObjectServerError;
import io.realm.Realm;
import io.realm.SyncUser;
import io.realm.realmtasks.auth.facebook.FacebookAuth;
import io.realm.realmtasks.auth.google.GoogleAuth;
import io.realm.realmtasks.model.TaskList;
import io.realm.realmtasks.model.TaskListList;

import static io.realm.realmtasks.RealmTasksApplication.AUTH_URL;

public class SignInActivity extends AppCompatActivity implements SyncUser.Callback {

    public static final String ACTION_IGNORE_CURRENT_USER = "action.ignoreCurrentUser";

    private AutoCompleteTextView usernameView;
    private EditText passwordView;
    private View progressView;
    private View loginFormView;
    private FacebookAuth facebookAuth;
    private GoogleAuth googleAuth;

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
        if (savedInstanceState == null) {
            if (!ACTION_IGNORE_CURRENT_USER.equals(getIntent().getAction())) {
                final SyncUser user = SyncUser.currentUser();
                if (user != null) {
                    loginComplete(user);
                }
            }
        }

        // Setup Facebook Authentication
        facebookAuth = new FacebookAuth((LoginButton) findViewById(R.id.login_button)) {
            @Override
            public void onRegistrationComplete(final LoginResult loginResult) {
                UserManager.setAuthMode(UserManager.AUTH_MODE.FACEBOOK);
                SyncCredentials credentials = SyncCredentials.facebook(loginResult.getAccessToken().getToken());
                SyncUser.loginAsync(credentials, AUTH_URL, SignInActivity.this);
            }
        };

        // Setup Google Authentication
        googleAuth = new GoogleAuth((SignInButton) findViewById(R.id.google_sign_in_button), this) {
            @Override
            public void onRegistrationComplete(GoogleSignInResult result) {
                UserManager.setAuthMode(UserManager.AUTH_MODE.GOOGLE);
                GoogleSignInAccount acct = result.getSignInAccount();
                SyncCredentials credentials = SyncCredentials.google(acct.getIdToken());
                SyncUser.loginAsync(credentials, AUTH_URL, SignInActivity.this);
            }

            @Override
            public void onError(String s) {
                super.onError(s);
            }
        };
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        googleAuth.onActivityResult(requestCode, resultCode, data);
        facebookAuth.onActivityResult(requestCode, resultCode, data);
    }

    private void loginComplete(SyncUser user) {
        UserManager.setActiveUser(user);

        createInitialDataIfNeeded();

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
            SyncUser.loginAsync(SyncCredentials.usernamePassword(email, password, false), RealmTasksApplication.AUTH_URL, this);
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

    @Override
    public void onSuccess(SyncUser user) {
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
                errorMsg = "The provided credentials are invalid!"; // This message covers also expired account token
                break;
            default:
                errorMsg = error.toString();
        }
        Toast.makeText(SignInActivity.this, errorMsg, Toast.LENGTH_LONG).show();
    }

    private static void createInitialDataIfNeeded() {
        final Realm realm = Realm.getDefaultInstance();
        //noinspection TryFinallyCanBeTryWithResources
        try {
            if (realm.where(TaskListList.class).count() != 0) {
                return;
            }
            realm.executeTransaction(new Realm.Transaction() {
                @Override
                public void execute(Realm realm) {
                    if (realm.where(TaskListList.class).count() == 0) {
                        final TaskListList taskListList = realm.createObject(TaskListList.class, 0);
                        final TaskList taskList = new TaskList();
                        taskList.setId(RealmTasksApplication.DEFAULT_LIST_ID);
                        taskList.setText(RealmTasksApplication.DEFAULT_LIST_NAME);
                        taskListList.getItems().add(taskList);
                    }
                }
            });
        } finally {
            realm.close();
        }
    }
}

