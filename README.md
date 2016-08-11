# RealmTasks

A basic to-do app, designed as a homage to [Clear for iOS](http://realmacsoftware.com/clear/).

**Warning:** This project is very much a work in progress, being used as a testbed for new Realm technologies.
It is in no way a fully feature-complete product, nor is it ever meant to be an actual competitor for the Clear app.

## Prerequisites

* Xcode 7.3.1.
* CocoaPods 1.0.1.
* AWS credentials for the `realm-ci-artifacts` bucket.
* An S3 browser, like [Transmit](https://panic.com/transmit/).
* Git configured with SSH and access to the <https://github.com/realm/cocoapods-specs-private> repo.

## 1. Obtain the Realm Mobile Platform Package

This version of RealmTasks is compatible with the mobile platform package available in the `realm-ci-artifacts`
S3 bucket at this path: `bundle/0.27.1-1/realm-mobile-platform-0.27.1-1.tar.gz`.

Once you have it, double-click it to extract its contents.

## 2. Start Object Server

Double-click the `start-object-server.command` script in the package obtained above.

## 3. Build and Run RealmTasks

1. Run `pod install` from the root of this repo.
2. Open `RealmTasks.xcworkspace` with Xcode 7.3.1.
3. Select either the "RealmTasks macOS" or "RealmTasks iOS" depending on which platform you'd like to try the app on.
4. Click the "Build and Run" icon in the upper left of Xcode (play icon).
5. When the app launches, tap/click "Register" if this is the first time you're trying the app, or "Log In" if you've
   already created an account.
6. Optional: If you'd like to run the app on a physical iPhone, you'll need to have code signing set up with Xcode, and
   the iPhone should be connected on the same local network as your Mac running the object server.

At this point, you can start creating items, managing lists, and you'll see your actions reflected in real time in other
running instances of the app.

We recommend that you run at least two instances of the app together to really show off sync in action.

## 5. Access Realm Files with the Realm Browser

1. Open the "Realm Browser" app included in the package obtained above, and close the initial 'Open' dialog.
2. Choose `File > Open Sync URL...`
3. In the Object Server logs, search for a line matching something like
   `Received: BIND(server_path='/dfd6b60dac64408cacc8ac447484622f/realmtasks'` and copy the long hexadecimal string.
   This is the user ID.
4. Paste the following into the Realm Browser's Sync Server URL field, replacing `<user id>` with the user ID you just
   copied: `realm://127.0.0.1:7800/<user id>/realmtasks`.
5. In the Object Server logs, search for a line matching something like `Your admin access token is:` and copy the long
   hexadecimal string, including the two trailing equals `==`.
   This is the admin access token for your instance of the object server.
6. Paste the admin access token you just copied into the Realm Browser's Signed User Token field.
7. Click "Open".
8. If the Browser reports it cannot open the Realm file because it is empty, add a task on one of the instances of
   RealmTasks running on a device and try again.
