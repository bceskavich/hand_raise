import React, { Component } from 'react';
import { Redirect, match as Match } from 'react-router-dom';
import { Channel } from 'phoenix';
import socket, { joinChannel } from '../lib/socket';
import SessionUser from './SessionUser';
import UserForm from './UserForm';
import { SessionUser as User } from '../interfaces';

interface SessionProps {
  match: Match<{ id: string }>;
}

interface SessionState {
  users: User[];
  sessionId: string;
  currentUserId: string;
  isConnecting: boolean;
  error: boolean;
  channel?: Channel;
}

export default class Session extends Component<SessionProps, SessionState> {
  constructor(props: SessionProps) {
    super(props);
    this.state = {
      users: [],
      sessionId: props.match.params.id,
      currentUserId: window.currentUser.id,
      isConnecting: true,
      error: false,
    }
  }

  get currentUser() {
    const { users, currentUserId } = this.state;
    return users.find(({ id }) => id === currentUserId);
  }

  async componentDidMount() {
    const { sessionId } = this.state;

    try {
      const {
        channel,
        response: { users },
      } = await joinChannel(socket, `session:${sessionId}`);

      channel.on('state_change', ({ users }) => this.setState({ users }));
      this.setState({ channel, users, isConnecting: false });
    } catch (e) {
      this.setState({ isConnecting: false, error: true });
    }
  }

  toggle = () => {
    const { channel, currentUserId } = this.state;
    channel && channel.push('toggle_raised', { user_id: currentUserId });
  };

  renderSession() {
    const { channel, users, currentUserId, sessionId } = this.state;

    return (
      <div>
        <div>Current Session: {sessionId}</div>

        {!this.currentUser && <UserForm channel={channel} />}

        {users &&
          users.map((user, index) => (
            <SessionUser
              key={index}
              user={user}
              currentUserId={currentUserId}
            />
          ))}

        {this.currentUser && (
          <button onClick={this.toggle}>
            {this.currentUser.is_raised ? 'Lower Hand' : 'Raise Hand'}
          </button>
        )}
      </div>
    );
  }

  render() {
    const { channel, isConnecting, error } = this.state;

    if (error) {
      return <Redirect to="/404" />;
    } else if (isConnecting) {
      return <div>Loading...</div>;
    } else if (channel) {
      return this.renderSession();
    }

    return null;
  }
}
