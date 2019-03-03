import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import Lobby from './components/Lobby';
import Session from './components/Session';

const Router = () => (
  <BrowserRouter>
    <React.Fragment>
      <Route exact path="/" component={Lobby} />
      <Route path="/:id" component={Session} />
      <Route path="/404" render={() => <h1>NotFound</h1>} />
    </React.Fragment>
  </BrowserRouter>
);

export default Router;
