'use strict';

import React from 'react';
import { AsyncStorage, Text, TextInput, View } from 'react-native';
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
                <View style={[styles.loginRow]}>
                    <Text style={styles.loginTitle}>RealmTasks</Text>
                </View>
                <View style={[styles.loginRow]}>
                    <Text style={styles.loginLabel1}>Login:</Text>
                </View>
                <View style={[styles.loginRow]}>
                    <TextInput style={styles.loginInput1}
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
                <View style={[styles.loginRow]}>
                    <Text style={styles.loginLabel2}>Password:</Text>
                </View>
                <View style={[styles.loginRow]}>
                    <TextInput
                        style={styles.loginInput2}
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
                <View style={[styles.loginRow]}>
                    <Text style={styles.loginErrorLabel}>{this.state.error}</Text>
                </View>
            </View>
        );
    }

};
