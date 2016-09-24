# RealmTasks

A basic task management app, designed as a *homage* to [Realmac Software's Clear](http://realmacsoftware.com/clear),
with their knowledge and permission.

**Warning:** This project is very much a work in progress, being used as a testbed for new Realm technologies.
It is in no way a fully feature-complete product, nor is it ever meant to be an actual competitor for the Clear app.

## Prerequisites

* Xcode 7.3.1.
* CocoaPods 1.0.1.
* Access to <https://labs.realm.io>.
* Git configured with SSH and access to the <https://github.com/realm/cocoapods-specs-private> repo.

## 1. Get the Realm Mobile Platform Package and start the Object Server

1. Download and extract the Realm Mobile Platform package from <https://labs.realm.io/gs>.
2. Double-click the `start-object-server.command` script in the package obtained above.

## 2. Build and Run RealmTasks

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

## 3. Access Realm Files with the Realm Browser

1. Launch the "Realm Browser" app included in the package obtained above and click "Open Sync URL...".
2. Paste the following into the Realm Browser's Sync Server URL field: `realm://127.0.0.1:7800/~/realmtasks`.
3. Enter the same username and password as you used when running RealmTasks and click "Open".
