import React, { Component } from 'react';
import { Redirect } from 'react-router-dom';
import { Channel } from 'phoenix';
import socket, { joinChannel, push } from '../lib/socket';
import JoinSessionForm from './JoinSessionForm';

interface LobbyState {
  channel?: Channel;
  sessionId?: string;
}

export default class Lobby extends Component<{}, LobbyState> {
  readonly state: LobbyState = {
    channel: undefined,
    sessionId: undefined,
  }

  async componentDidMount() {
    const { channel } = await joinChannel(socket, 'room:lobby');
    this.setState({ channel });
  }

  createSession = async () => {
    const { channel } = this.state;
    const { session_id: sessionId } = await push(channel, 'create_session');
    this.setState({ sessionId });
  };

  render() {
    const { channel, sessionId } = this.state;
    return (
      <div>
        <h1>Hand Raise</h1>
        {channel && !sessionId && (
          <button onClick={this.createSession}>Create Session</button>
        )}
        <JoinSessionForm />
        {sessionId && <Redirect to={`/${sessionId}`} />}
      </div>
    );
  }
}
