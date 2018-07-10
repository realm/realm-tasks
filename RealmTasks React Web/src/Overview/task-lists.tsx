import gql from 'graphql-tag';
import * as React from 'react';
import {
  Subscription as ApolloSubscription,
  SubscriptionResult,
} from 'react-apollo';

import { ITaskList } from '../models';

export const query = gql`
  subscription {
    tasklists {
      id
      text
      completed
    }
  }
`;

interface IData {
  tasklists: Array<Pick<ITaskList, 'id' | 'text' | 'completed'>>;
}

interface ISubscriptionProps {
  children: (result: SubscriptionResult<IData>) => React.ReactNode;
}

export const Subscription = (props: ISubscriptionProps) => (
  <ApolloSubscription subscription={query} children={props.children} />
);
