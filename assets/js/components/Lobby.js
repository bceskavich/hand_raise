import React, { Component } from 'react';
import { sortBy } from 'lodash';
import { channel, presence } from '../lib/socket';
import SessionUser from './SessionUser';

export default class Lobby extends Component {
  constructor(props) {
    super(props);
    this.state = {
      session: window.session,
      users: []
    };
  }

  get currentUser() {
    const { users, session } = this.state;
    return users.find(({ id }) => id === session.user) || {};
  }

  componentDidMount() {
    presence.onSync(() =>
      presence.list((id, { metas }) => this.handleUsersChange(metas))
    );
  }

  handleUsersChange(metas) {
    const users = metas.map(meta => ({
      id: meta.id,
      isHandRaised: meta.is_hand_raised
    }));
    this.setState({ users: sortBy(users, 'id') });
  }

  handleClick() {
    channel.push('user_raise_changed', {
      id: this.currentUser.id,
      is_hand_raised: !this.currentUser.isHandRaised
    });
  }

  render() {
    const { users, session } = this.state;
    console.log(users);
    return (
      <div>
        <h1>Hand Raise</h1>
        {users.map((user, i) => (
          <SessionUser key={i} user={user} currentUser={session.user} />
        ))}
        <button onClick={this.handleClick.bind(this)}>
          {this.currentUser.isHandRaised ? 'Lower' : 'Raise'} Hand
        </button>
      </div>
    );
  }
}
