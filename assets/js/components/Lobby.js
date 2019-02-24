import React, { Component } from 'react';
import { Redirect } from 'react-router-dom';
import socket, { joinChannel, push } from '../lib/socket';
import Session from './Session';
import JoinSessionForm from './JoinSessionForm';

export default class Lobby extends Component {
  constructor(props) {
    super(props);
    this.state = {
      channel: null,
      sessionId: null,
    };
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
    const { users, channel, sessionId } = this.state;
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
