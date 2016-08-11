# RealmTasks

A basic to-do app, designed as a homage to [Clear for iOS](http://realmacsoftware.com/clear/).

**Warning:** This project is very much a work in progress, being used as a testbed for new Realm technologies. It is in no way a fully feature-complete product, nor is it ever meant to be an actual competitor for the Clear app.

## 1. Generating the Necessary Sync Credentials for the RealmTasks App

1. Open the [Realm Sync Server app](https://github.com/realm/realm-browser-osx-private/tree/sync).
2. Click on `Manage Credentials`.
3. Click the `+` icon and enter *realmtasks* into the `Identity` field, and *io.realm.RealmTasks* in the `App Bundle ID` field.
4. Click `Save`.
5. Click on `Copy Token`, and close the window. The generated token will now be in your clipboard.

## 2. Setting up the RealmTasks App

1. Generate and copy a token from Realm Sync Server, following the instructions above.
2. Open `RealmTasks.xcworkspace` in Xcode, and navigate to the `AppDelegate.swift` file.
3. Get the IP address of the computer on which you plan to run Realm Sync Server (e.g. in Terminal, enter command `ipconfig getifaddr en0`) and set the `configuration.syncServerURL` property URL on line 34 to `realm://<Computer IP Address>:7800/public/realmtasks`
4. Paste the token you generated in Realm Sync Server into the `configuration.syncUserToken` property on line 35.
5. Save and build the project onto as many devices as you wish.

## 3. Running Realm Sync Server

1. Ensure you’ve generated a `realmtasks` token under the `Manage Credentials` dialog.
2. In `Host`, enter this computer’s IP address (e.g. `ipconfig getifaddr en0` in Terminal) and make sure to press ‘return’ when done, or click out of the text field.
3. Press `Start server` to start running the server locally on your computer.

## 4. Running RealmTasks with Sync Enabled

1. Ensure the previous items have all been completed.
2. Build RealmTasks, and deploy it to devices connected to the same network as the computer running Realm Sync Server.
3. No further action is necessary. RealmTasks will connect to and download data from the Realm Sync Server automatically upon execution.

## 5. Introspecting Realm Files with Realm Browser

1. Open Realm Browser, and close the initial ‘Open’ dialog.
2. Choose `File > Open Sync URL…`
3. Copy and paste the `syncServerURL` and `syncUserToken` values from RealmTasks’ app delegate into the text fields displayed.
4. If the Browser has reports it cannot open the Realm file because it is empty, add a to-do item on one of the instances of RealmTasks running on a device and try again.
