import React from 'react';
import ReactDOM from 'react-dom';
import Router from './Router';

import '../css/app.css';
import 'phoenix_html';

declare global {
  interface Window {
    currentUser: {
      id: string;
      token: string;
    }
  }
}

ReactDOM.render(<Router />, document.getElementById('main'));
