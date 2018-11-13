import { Socket, Presence } from 'phoenix';

const socket = new Socket('/socket', {
  params: { token: window.session.userToken }
});
socket.connect();

export const channel = socket.channel('room:lobby', {});
channel
  .join()
  .receive('ok', resp => console.log('Joined successfully', resp))
  .receive('error', resp => console.log('Unable to join', resp));

export const presence = new Presence(channel);
