////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

'use strict';

import Realm from 'realm';
import config from '../config';

class Task extends Realm.Object {}
Task.schema = {
    name: 'Task',
    properties: {
        completed: {type: 'bool', default: false},
        text: 'string',
    },
};

class TaskList extends Realm.Object {}
TaskList.schema = {
    name: 'TaskList',
    properties: {
        id: 'string',
        text: 'string',
        completed: {type: 'bool', default: false},
        items: {type: 'list', objectType: 'Task'},
    },
    primaryKey: 'id'
};

function connect (action, username, password, callback) {
    username = username.trim();
    password = password.trim();
    if(username === '') {
        return callback(new Error('Username cannot be empty'));
    } else if (password === '') {
        return callback(new Error('Password cannot be empty'));
    }
         
    Realm.Sync.User[action](config.auth_uri, username, password,
        (error, user) => {
            if (error) {
                return callback(new Error('Failed to ' + action));
            } else {
                my_exports.realm = new Realm({
                    schema: [Task, TaskList],
                    sync: {
                        user,
                        url: config.db_uri
                    },
                    path: config.db_path
                });
                return callback(null, my_exports.realm); // TODO errors
            }
        }
    );
}

const my_exports = {
    login: connect.bind(undefined, 'login'),
    register: connect.bind(undefined, 'register'),
    realm: null,
    connect
};
export default my_exports;
