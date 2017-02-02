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

import React from 'react';
import { AsyncStorage, Text, TextInput, View, Button } from 'react-native';
import RealmTasks from './realm-tasks';
import styles from './styles';
import TodoApp from './todo-app';
import config from '../config';


export default class LoginScreen extends React.Component {

    constructor (props) {
        super(props);
        this.state = {login: config.default_login, password: config.default_password};
        this._submit = this.submit.bind(this);
        this.user = null;
    }

    login () {
        RealmTasks.login(
            this.state.login,
            this.state.password,
            (error, realm) => {
                if (error) {
                    console.log('error logging in', error);
                    this.state.error = error;
                } else {
                    delete this.state.error;
                    console.log('logged in');
                }
                this.forceUpdate();
            }
        );
    }

    register () {
        RealmTasks.register(
            this.state.login,
            this.state.password,
            (error, realm) => {
                if (error) {
                    console.log('error registering in', error);
                    this.state.error = error;
                } else {
                    delete this.state.error;
                    console.log('logged in');
                }
                this.forceUpdate();
            }
        );
    }

    submit () {
        RealmTasks.login(
            this.state.login,
            this.state.password,
            (error, realm) => {
                if (error) {
                    console.log('error logging in', error);
                    this.state.error = error;
                } else {
                    delete this.state.error;
                    console.log('logged in');
                }
                this.forceUpdate();
            }
        );

    }

    render () {
        if (RealmTasks.realm!==null) return <TodoApp/>; // logged in already

        return (
            <View style={[styles.loginView]}>
                <View>
                    <Text style={[styles.loginRow,styles.loginTitle]}>RealmTasks</Text>
                </View>
                <View>
                    <Text style={[styles.loginRow,styles.loginLabel1]}>Login:</Text>
                </View>
                <View>
                    <TextInput style={[styles.loginRow,styles.loginInput1]}
                        value={this.state.login}
                        onChangeText={ login => this.setState({
                            login,
                            password: this.state.password
                        }) }
                        editable = {true}
                        placeholder = "your login here"
                        maxLength = {40}
                        onSubmitEditing={this._submit}
                    ></TextInput>
                </View>
                <View>
                    <Text style={[styles.loginRow,styles.loginLabel2]}>Password:</Text>
                </View>
                <View>
                    <TextInput
                        style={[styles.loginRow,styles.loginInput2]}
                        value={this.state.password}
                        onChangeText={ password => this.setState({
                            login: this.state.login,
                            password
                        }) }
                        editable = {true}
                        placeholder = "your password here"
                        maxLength = {40}
                        onSubmitEditing={this._submit}
                    />
                </View>
                <View>
                    <Text style={[styles.loginRow, styles.LoginGap]}></Text>
                </View>
                <View>
                    <Button title="Log in" onPress={ this.login.bind(this) }/>
                </View>
                <View>
                    <Text style={[styles.loginRow, styles.LoginGap]}></Text>
                </View>
                <View>
                    <Button title="Register" onPress={ this.register.bind(this) } />
                </View>
                <View>
                    <Text style={[styles.loginRow,styles.loginErrorLabel]}>{this.state.error}</Text>
                </View>
            </View>
        );
    }

};
