import React, { FC, useState } from 'react';
import { Channel } from 'phoenix';
import { push } from '../lib/socket';

interface Props {
  channel?: Channel;
}

const UserForm: FC<Props> = ({ channel }) => {
  const [name, setName] = useState('');

  return (
    <form
      onSubmit={e => {
        e.preventDefault();
        push(channel, 'set_user', { name });
      }}
    >
      <label>
        Name:
        <input
          type="text"
          value={name}
          onChange={e => setName(e.target.value)}
        />
      </label>
      <input type="submit" value="Join" />
    </form>
  );
}

export default UserForm;
