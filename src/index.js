import './main.css';
import registerServiceWorker from './registerServiceWorker';


/**
 * This runs the normal demo 
 */
import { Elm } from './examples/Demo.elm';
Elm.Demo.init({
  node: document.getElementById('root')
});

/**
 * This runs the Live translation demo. 
 */
// import { Elm } from './examples/LiveTranslation.elm';
// Elm.LiveTranslation.init({
//   node: document.getElementById('root')
// });

registerServiceWorker();
