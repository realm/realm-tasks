import {
  ApolloClient,
  concat,
  HttpLink,
  InMemoryCache,
  split,
} from 'apollo-client-preset';
import { WebSocketLink } from 'apollo-link-ws';
import { getMainDefinition } from 'apollo-utilities';
import { GraphQLConfig, User } from 'realm-graphql-client';

export const createClient = async (user: User, path: string) => {
  const config = await GraphQLConfig.create(user, path);
  const httpLink = concat(
    config.authLink,
    // Note: if using node.js, you'll need to provide fetch as well.
    new HttpLink({ uri: config.httpEndpoint }),
  );

  // Note: if using node.js, you'll need to provide webSocketImpl as well.
  const webSocketLink = new WebSocketLink({
    uri: config.webSocketEndpoint,
    options: {
      connectionParams: config.connectionParams,
    },
  });

  const link = split(
    ({ query }) => {
      const definition = getMainDefinition(query);
      return (
        definition.kind === 'OperationDefinition' &&
        definition.operation === 'subscription'
      );
    },
    webSocketLink,
    httpLink,
  );

  return new ApolloClient({
    link,
    cache: new InMemoryCache(),
  });
};
