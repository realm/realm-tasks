import { ApolloClient } from 'apollo-client-preset';
import * as React from 'react';
import { ApolloProvider } from 'react-apollo';
import { Credentials, User } from 'realm-graphql-client';

import { Overview } from './Overview';
import * as graphql from './services/graphql';

const USER_STORAGE_KEY = 'user';

type AppState =
  | {
      status: 'authenticating';
    }
  | {
      status: 'authenticated';
      client: ApolloClient<any>;
    };

export class App extends React.Component<{}, AppState> {
  public state: AppState = {
    status: 'authenticating',
  };

  public async componentDidMount() {
    const user = await this.getUser();
    const client = await graphql.createClient(user, '/~/test');
    this.setState({ status: 'authenticated', client });
  }

  public render() {
    return this.state.status === 'authenticated' ? (
      <ApolloProvider client={this.state.client}>
        <Overview />
      </ApolloProvider>
    ) : (
      <p>Authenticating ...</p>
    );
  }

  protected async getUser() {
    const userFromStorage = window.localStorage.getItem(USER_STORAGE_KEY);
    if (userFromStorage) {
      const userProperties = JSON.parse(userFromStorage);
      return new User(userProperties);
    } else {
      const credentials = Credentials.usernamePassword(
        'some-username',
        'some-password',
      );
      const user = await User.authenticate(
        credentials,
        'https://decisionmate-development.us1a.cloud.realm.io',
      );
      // Store this new user in the local storage
      window.localStorage.setItem(
        USER_STORAGE_KEY,
        JSON.stringify({
          identity: user.identity,
          isAdmin: user.isAdmin,
          server: user.server,
          token: user.token,
        }),
      );
      return user;
    }
  }
}
