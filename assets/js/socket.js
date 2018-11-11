import { Socket } from "phoenix";

const STATE = { handRaised: false };

let socket = new Socket("/socket", {
  params: {
    token: window.session.userToken
  }
});

socket.connect();

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("room:lobby", {});
channel
  .join()
  .receive("ok", resp => {
    console.log("Joined successfully", resp);
  })
  .receive("error", resp => {
    console.log("Unable to join", resp);
  });

channel.on("presence_list", ({ users }) => {
  if (users) {
    users.metas.forEach(({ user }) => addUser(user));
  }
});
channel.on("user_joined", ({ user }) => addUser(user));

function addUser(user) {
  let node = document.createElement("p");
  node.id = user;
  let text = user;
  if (user === window.session.user) {
    text += " (you)";
  }
  node.textContent = text;

  document.getElementById("main").appendChild(node);
}

channel.on("user_left", ({ user }) => {
  let node = document.getElementById(user);
  if (node) {
    node.remove();
  }
});

channel.on("user_hand_raised", ({ user }) => {
  if (user !== window.session.user) {
    displayRaisedHand(user);
  }
});
channel.on("user_hand_lowered", ({ user }) => {
  if (user !== window.session.user) {
    displayLoweredHand(user);
  }
});

const button = document.getElementById("button");

button.addEventListener("click", () => {
  if (STATE.handRaised) {
    lowerHand();
  } else {
    raiseHand();
  }
});

function raiseHand() {
  STATE.handRaised = true;
  displayRaisedHand(window.session.user);
  button.innerHTML = "Lower Hand";
  channel.push("user_hand_raised", { user: window.session.user });
}

function displayRaisedHand(id) {
  let node = document.getElementById(id);
  node.innerHTML = node.innerHTML + " (raised)";
}

function lowerHand() {
  STATE.handRaised = false;
  displayLoweredHand(window.session.user);
  button.innerHTML = "Raise Hand";
  channel.push("user_hand_lowered", { user: window.session.user });
}

function displayLoweredHand(id) {
  let node = document.getElementById(id);
  node.innerHTML = node.innerHTML.replace(" (raised)", "");
}

export default socket;
