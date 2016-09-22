package io.realm.realmtasks;

import io.realm.Realm;
import io.realm.SyncConfiguration;
import io.realm.User;

public class UserManager {

    // Configure Realm for the current active user
    public static void setActiveUser(User user) {
        SyncConfiguration defaultConfig = new SyncConfiguration.Builder(user, RealmTasksApplication.REALM_URL).build();
        Realm.setDefaultConfiguration(defaultConfig);
    }
}
