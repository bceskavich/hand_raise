import React, { useState } from 'react';

export default function JoinSessionForm() {
  const [sessionId, setSessionId] = useState('');

  return (
    <form
      onSubmit={e => {
        e.preventDefault();
        window.location.assign(`/${sessionId}`);
      }}
    >
      <label>
        Session ID:
        <input
          type="text"
          placeholder="session-id"
          value={sessionId}
          onChange={e => setSessionId(e.target.value)}
        />
      </label>
      <input type="submit" value="Join" />
    </form>
  );
}
