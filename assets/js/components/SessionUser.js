import React from 'react';

export default ({ user, currentUser }) => {
  return (
    <p>
      {user.id} {user.id === currentUser ? ' (you)' : ''}{' '}
      {user.isHandRaised ? '(raised)' : ''}
    </p>
  );
};
