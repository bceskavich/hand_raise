import React from 'react';

export default ({ user, currentUserId }) => (
  <div>
    {user.name} {user.id === currentUserId ? ' (you)' : ''}{' '}
    {user.is_raised ? ' (raised)' : ''}
  </div>
);
