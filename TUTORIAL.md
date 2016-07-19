# Installation and Usage Instructions

This package is a technical demo for testing out Realm Sync. It provides a basic iOS app named RealmTasks that can demonstrate Realm Sync in a real-world use case. It also includes the necessary utility apps for running a server, and introspecting Realm database files.

This bundle contains the following folders:

### App 
The app project and all source code necessary for building a new copy of RealmTasks. All dependencies have been included, so it should simply build in Xcode straight out of the box
### Tools
This folder contains a copy of Realm Browser and Realm Sync Server. Realm Browser allows you to connect to and introspect Realm files being managed by Realm Sync. 

Realm Sync Server runs a local instance of Realm Sync on your computer, allowing you to test Sync in both the iOS Simulator, as well as devices connected to the same network.

## Setting up and testing RealmTasks with Realm Sync Server
In order to begin trying out Realm Sync, it is necessary for you to generate the necessary URL and security token tailored to your computer in order for Realm Sync Server to properly run.

The following steps will take you through all of the necessary items needed to be done to set up Realm Sync on a local machine, and to then configure the RealmTasks app to connect to it.

### 1. Generating the Necessary Sync Credentials for the RealmTasks App
1. Open the Realm Sync Server app.
2. Click on `Manage Credentials`.
3. Click the `+` icon and enter *realmtasks* into the `Identity` field, and *io.realm.RealmTasks* in the `App Bundle ID` field.
4. Click `Save`.
5. Click on `Copy Token`, and close the window. The generated token will now be in your clipboard.

### 2. Setting up the RealmTasks App
1. Generate and copy a token from Realm Sync Server, following the instructions above.
2. Open `RealmTasks.xcworkspace` in Xcode, and navigate to the `AppDelegate.swift` file.
3. Get the IP address of the computer on which you plan to run Realm Sync Server (e.g. in Terminal, enter command `ipconfig getifaddr en0`) and set the `configuration.syncServerURL` property URL on line 34 to `realm://<Computer IP Address>:7800/public/realmtasks`
4. Paste the token you generated in Realm Sync Server into the `configuration.syncUserToken` property on line 35.
5. Save and build the project onto as many devices as you wish.

### 3. Running Realm Sync Server
1. Ensure you’ve generated a `realmtasks` token under the `Manage Credentials` dialog.
2. In `Host`, enter this computer’s IP address (e.g. `ipconfig getifaddr en0` in Terminal) and make sure to press ‘return’ when done, or click out of the text field.
3. Press `Start server` to start running the server locally on your computer.

### 4. Running RealmTasks with Sync Enabled
1. Ensure the previous items have all been completed.
2. Build RealmTasks, and deploy it to devices connected to the same network as the computer running Realm Sync Server.
3. No further action is necessary. RealmTasks will connect to and download data from the Realm Sync Server automatically upon execution.

### 5. Introspecting Realm Files with Realm Browser
1. Open Realm Browser, and close the initial ‘Open’ dialog.
2. Choose `File > Open Sync URL…`
3. Copy and paste the `syncServerURL` and `syncUserToken` values from RealmTasks’ app delegate into the text fields displayed.
4. If the Browser has reports it cannot open the Realm file because it is empty, add a to-do item on one of the instances of RealmTasks running on a device and try again.
