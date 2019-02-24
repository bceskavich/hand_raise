import React, { useState } from 'react';
import { push } from '../lib/socket';

export default function UserForm({ channel }) {
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
