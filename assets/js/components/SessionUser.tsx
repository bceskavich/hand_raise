import React, { FC } from 'react';
import { SessionUser } from '../interfaces';

interface Props {
  currentUserId: string;
  user: SessionUser;
}

const Component: FC<Props> = ({ user, currentUserId }) => (
  <div>
    {user.name} {user.id === currentUserId ? ' (you)' : ''}{' '}
    {user.is_raised ? ' (raised)' : ''}
  </div>
);

export default Component;
