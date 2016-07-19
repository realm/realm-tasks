# RealmTasks

A basic to-do app, designed as a homage to [Clear for iOS](http://realmacsoftware.com/clear/).

**Warning:** This project is very much a work in progress, being used as a testbed for new Realm technologies. It is in no way a fully feature-complete product, nor is it ever meant to be an actual competitor for the Clear app.

## Running a Local Sync Server
1. [Download the Sync Server and Realm Sync Browser](https://github.com/realm/realm-sync/releases/tag/v0.23.2) from the Realm Sync repo.
2. Open the Realm Sync Server.
3. Click 'Manage Credentials' and click '+' to add a new entry.
4. Type 'realmclear' as the identity, click 'Save', and then click 'Copy Token'.
5. Set the `syncServerURL` property to `NSURL(string:"realm://[address]:[port]/realmclear")` for your default `Realm.Configuration`.
6. Set the token you copied from 'Manage Credentials' as the `syncUserToken` property in the same configuration object.
7. Click 'Start server' and run your app.

## Viewing the data in Realm Browser
1. Open the Realm Sync Browser.
2. Choose 'File > New Sync File with URL'.
3. Save the Realm to a common directory, and fill in the same URL and user token as the iOS app.
4. When the Realm file opens in the Browser, modify the values and observe their changes in the iOS app.
