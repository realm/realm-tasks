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

package io.realm.realmtasks.auth.facebook;

import android.content.Intent;
import android.support.v4.app.FragmentActivity;

import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.login.LoginResult;
import com.facebook.login.widget.LoginButton;

/**
 * Provide authentication using users Facebook account.
 */

public abstract class FacebookAuth {
    private final LoginButton loginButton;
    private final CallbackManager callbackManager;

    public FacebookAuth(final LoginButton loginBtn) {
        callbackManager = CallbackManager.Factory.create();
        this.loginButton = loginBtn;
        loginButton.setReadPermissions("email");

        // Callback registration
        loginButton.registerCallback(callbackManager, new FacebookCallback<LoginResult>() {

            @Override
            public void onSuccess(LoginResult loginResult) {
                onRegistrationComplete(loginResult);
            }

            @Override
            public void onCancel() {
                onAuthCancelled();
            }

            @Override
            public void onError(FacebookException exception) {
                onAuthError();
            }
        });

    }

    /**
     * Called if the authentication is cancelled by the user.
     *
     * Adapter method, developer might want to override this method  to provide
     * custom logic.
     */
    public void onAuthCancelled() {}

    /**
     * Called if the authentication fails.
     *
     * Adapter method, developer might want to override this method  to provide
     * custom logic.
     */
    public void onAuthError () {}

    /**
     * Notify this class about the {@link FragmentActivity#onResume()} event.
     */
    public final void onActivityResult(int requestCode, int resultCode, Intent data) {
        callbackManager.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * Called once we obtain a token from Facebook API.
     * @param loginResult contains the token obtained from Facebook API.
     */
    public abstract void onRegistrationComplete(final LoginResult loginResult);
}
