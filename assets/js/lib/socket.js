import { Socket, Presence } from 'phoenix';

const socket = new Socket('/socket', {
  params: { token: window.currentUser.token },
});

socket.connect();

export default socket;

export function joinChannel(socket, channelName, args = {}) {
  const channel = socket.channel(channelName, args);

  return new Promise((resolve, reject) => {
    channel
      .join()
      .receive('ok', response => resolve({ channel, response }))
      .receive('error', response => reject({ response }));
  });
}

export function push(channel, msg, args = {}) {
  return new Promise((resolve, reject) => {
    channel
      .push(msg, args)
      .receive('ok', resolve)
      .receive('error', reject)
      .receive('timeout', reject);
  });
}
