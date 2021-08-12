import * as sapper from '@sapper/app';
import firebase from 'firebase/app';
import 'firebase/firestore';
import 'firebase/storage';
import 'firebase/auth';
import 'hammerjs';

import { getUserId } from './stores/user';

const config = {
	apiKey: 'AIzaSyBc64C8lLHCA2K9HRMCApwTgwAKme0IRKI',
	authDomain: 'scavenger-hunt-d4e84.firebaseapp.com',
	projectId: 'scavenger-hunt-d4e84',
	storageBucket: 'scavenger-hunt-d4e84.appspot.com',
	messagingSenderId: '986242176276',
	appId: '1:986242176276:web:821ffb67530947146b5e01',
};
// client side app has started
firebase.initializeApp(config);

let userId;

sapper.start({
	target: document.querySelector('body'),
});
