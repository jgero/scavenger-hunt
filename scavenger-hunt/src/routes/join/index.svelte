<script>
	import firebase from 'firebase/app';
	import { onDestroy, onMount } from 'svelte';
	import QRCode from 'qrcode';

	import { getUserId } from '../../stores/user';
	import { getLogger } from '../../stores/debug-logger.js';
	import RouteHeader from '../../components/RouteHeader.svelte';

	let userId, logger;
	let qrBase64;
	let unsub;
	let routesToJoin = [], unsubRoutesToJoin;
	onMount(() => {
		userId = getUserId();
		logger = getLogger();

		unsub = userId.subscribe((uid) => {
			if (!uid) {
				return;
			}
			const hostname = window.location.hostname;
			let addMeURL =
				hostname === 'localhost' ? 'http://localhost' : `https://${hostname}`;
			addMeURL += `/create/addUser/${uid}`;
			writeQrCode(addMeURL);
		unsubRoutesToJoin = firebase
			.firestore()
			.collection('routes').where("searchers", "array-contains", uid)
			.onSnapshot(
				(snapshot) => {
					routesToJoin = [];
					snapshot.forEach(doc => routesToJoin.push(doc.id));
					logger.log({
						logLevel: 'log',
						message: `routes to join for user ${uid} loaded`,
					});
				},
				(error) => {
					logger.log({
						logLevel: 'error',
						message: `could not fetch route data: ${JSON.stringify(error)}`,
					});
				}
			);
		});

	});

	function writeQrCode(dataString) {
		QRCode.toDataURL(dataString, (err, code) => {
			if (err) {
				logger.log({
					logLevel: 'log',
					message: `qr-gen errror: ${JSON.stringify(err)}`,
				});
			} else {
				logger.log({
					logLevel: 'log',
					message: `qr-gen with content: ${dataString}`,
				});
			}
			qrBase64 = code;
		});
	}

	onDestroy(() => {
		if (unsub) {
			unsub();
		}
		if(unsubRoutesToJoin)  {
unsubRoutesToJoin();
	}
	});
</script>

<RouteHeader title="Route beitreten" />

<main>
	<h2>Routen</h2>
<ul>
{#if $userId}
	<li>
	<a href="/join/{$userId}">Meiner eigenen Route beitreten</a>
			</li>
{/if}
{#each routesToJoin as route}
	<li>
	<a href="/join/{route}">Route von Benutzer {route}</a>
		</li>
{/each}
</ul>

<h2>Code um mich zu einer Route einzuladen</h2>

<img src={qrBase64} alt="Einladungs QR-Code" />
</main>

<style>
	main {
		padding: 1rem;
		overflow: auto;
		display: flex;
		flex-direction: column;
		justify-items: flex-start;
	}
	ul {
		margin: 0;
		padding: 0;
		max-width: 100%;
	}
	li {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-block-end: 1rem;
		padding-left: 1.5rem;
		padding-inline-start: 4rem;
	}
	img {
		max-width: 50%;
		align-self: center;
	}
	a {
		background-color: var(--primary);
		border-radius: 0.6rem;
		color: var(--primary-contrast);
		text-decoration: none;
		padding: 0.5rem;
		display: block;
		width: max-content;
	}
</style>


