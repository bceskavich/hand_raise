import { Socket, Channel } from 'phoenix';
import { SessionUser } from '../interfaces';

interface SessionData {
  users: SessionUser[];
}

interface JoinResponse {
  response: SessionData;
  channel: Channel;
}

interface PushResponse {
  session_id?: string;
}

const socket = new Socket('/socket', {
  params: { token: window.currentUser.token },
});

socket.connect();

export default socket;

export function joinChannel(
  socket: Socket,
  channelName: string,
  args = {}
): Promise<JoinResponse> {
  const channel = socket.channel(channelName, args);

  return new Promise((resolve, reject) => {
    channel
      .join()
      .receive('ok', response => resolve({ channel, response }))
      .receive('error', response => reject({ response }));
  });
}

export function push(
  channel: Channel | undefined,
  msg: string,
  args = {}
): Promise<PushResponse> {
  if (!channel) {
    return Promise.resolve({});
  }

  return new Promise((resolve, reject) => {
    channel
      .push(msg, args)
      .receive('ok', resolve)
      .receive('error', reject)
      .receive('timeout', reject);
  });
}
