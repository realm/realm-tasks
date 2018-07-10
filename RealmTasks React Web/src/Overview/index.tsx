import * as React from 'react';

import { Subscription } from './task-lists';

export const Overview = () => (
  <Subscription>
    {({ loading, error, data }) => (
      <section>
        <h1>Task Lists</h1>
        {error ? (
          <em>{error.message}</em>
        ) : loading ? (
          <p>Loading ...</p>
        ) : (
          <ul>
            {data.tasklists.map(tasklist => (
              <li key={tasklist.id}>{tasklist.text}</li>
            ))}
          </ul>
        )}
      </section>
    )}
  </Subscription>
);
