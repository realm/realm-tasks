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

package io.realm.realmtasks.auth.google;

import android.content.Intent;
import android.support.annotation.NonNull;
import android.support.v4.app.FragmentActivity;
import android.view.View;

import com.google.android.gms.auth.api.Auth;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.SignInButton;
import com.google.android.gms.common.api.GoogleApiClient;

import io.realm.realmtasks.R;

/**
 * * Provide authentication using users Google account registered with the device.
 */

public abstract class GoogleAuth implements GoogleApiClient.OnConnectionFailedListener {
    private GoogleApiClient mGoogleApiClient;
    private static final int RC_SIGN_IN = 10;

    public GoogleAuth(final SignInButton btnSignIn, final FragmentActivity fragmentActivity) {
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestEmail()
                .requestIdToken(fragmentActivity.getString(R.string.server_client_id))
                .build();

        mGoogleApiClient = new GoogleApiClient.Builder(fragmentActivity)
                .enableAutoManage(fragmentActivity /* FragmentActivity */, this /* OnConnectionFailedListener */)
                .addApi(Auth.GOOGLE_SIGN_IN_API, gso)
                .build();

        btnSignIn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent signInIntent = Auth.GoogleSignInApi.getSignInIntent(mGoogleApiClient);
                fragmentActivity.startActivityForResult(signInIntent, RC_SIGN_IN);
            }
        });
    }

    /**
     * Notify this class about the {@link FragmentActivity#onResume()} event.
     */
    public final void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == RC_SIGN_IN) {
            GoogleSignInResult result = Auth.GoogleSignInApi.getSignInResultFromIntent(data);
            handleSignInResult(result);
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public final void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
        if(!connectionResult.hasResolution()) {
            onError("Connection failed and has no resolution. code:" + connectionResult.getErrorCode());
        }
    }

    /**
     * Called once we obtain a token from Google Sign In API.
     * @param result contains the token obtained from Google Sign In API.
     */
    public abstract void onRegistrationComplete(final GoogleSignInResult result);

    /**
     * Called in case of authentication or other errors.
     *
     * Adapter method, developer might want to override this method  to provide
     * custom logic.
     */
    public void onError(String s) {}

    private void handleSignInResult(GoogleSignInResult result) {
        System.out.println("handleSignInResult:" + result.isSuccess());
        if (result.isSuccess()) {
            onRegistrationComplete(result);
        } else {

        }
    }
}
