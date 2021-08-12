<script context="module">
	export async function preload({ params }) {
		const [locationId, userId] = params.params;
		const routeId = params.routeId;
		return { routeId, locationId, userId };
	}
</script>

<script>
	import firebase from 'firebase/app';
	import { onMount, onDestroy } from 'svelte';
	import { getLogger } from '../../../stores/debug-logger';

	import RouteHeader from '../../../components/RouteHeader.svelte';
	import ImageCapture from '../../../components/ImageCapture.svelte';

	export let routeId, locationId, userId;
	let unsubSnapshotListener, logger, route, location;

	let newImageDataUrl = '',
		solutionText = '';
	const additionalButtons = [{ value: 'arrow_back', href: `/join/${routeId}` }];

	onMount(() => {
		logger = getLogger();
		unsubSnapshotListener = firebase
			.firestore()
			.collection('routes')
			.doc(routeId)
			.onSnapshot(
				(doc) => {
					if (!doc.exists) {
						logger.log({
							logLevel: 'log',
							message: 'snapshot is empty',
						});
						return;
					}
					logger.log({
						logLevel: 'log',
						message: `route of user ${routeId} loaded`,
					});
					route = doc.data();
					location = doc
						.data()
						.locations.find((location) => location.id === locationId);
					if (
						solutionText === '' &&
						location.solutions &&
						location.solutions[userId]
					) {
						solutionText = location.solutions[userId].solutionText;
					}
				},
				(error) => {
					logger.log({
						logLevel: 'error',
						message: `could not fetch route data: ${JSON.stringify(error)}`,
					});
				}
			);
	});

	onDestroy(() => {
		if (unsubSnapshotListener) {
			unsubSnapshotListener();
		}
	});

	async function getImageForLocation() {
		let url = null;
		try {
			url = await firebase
				.storage()
				.ref()
				.child(`${routeId}/${locationId}/${userId}`)
				.getDownloadURL();
		} catch (e) {
			logger.log({
				logLevel: 'error',
				message: `could not fetch image: ${JSON.stringify(e)}`,
			});
		}
		return url;
	}

	async function saveSolution() {
		route.lastEdit = new Date();
		let index = route.locations.findIndex((el) => el.id === locationId);
		// set solution for current user
		if (!route.locations[index].solutions) {
			route.locations[index].solutions = {};
		}
		route.locations[index].solutions[userId] = {
			hasImage: newImageDataUrl != '',
			solutionText,
		};
		await firebase.firestore().collection('routes').doc(routeId).set(route);
		if (newImageDataUrl) {
			await firebase
				.storage()
				.ref()
				.child(`${routeId}/${locationId}/${userId}`)
				.putString(newImageDataUrl, 'data_url');
		}
		logger.log({
			logLevel: 'log',
			message: `route updated`,
		});
	}
</script>

<RouteHeader title="Stationsbeweis erstellen" {additionalButtons} />

<main>
	<h1>{location ? location.name : ''}</h1>
	<div class="descriptionBox">
		<label for="description">Lösungstext</label>
		<textarea id="description" bind:value={solutionText} />
	</div>
	<div class="imageBox">
		<ImageCapture
			bind:imageDataUrl={newImageDataUrl}
			altImageUrlPromise={getImageForLocation}
		/>
	</div>
	<button class="material-icons submit" on:click={saveSolution}>save</button>
</main>

<style>
	main {
		width: 100%;
		overflow: hidden;
		padding: 1rem;
		box-sizing: border-box;
		display: grid;
		grid-template-areas: 'header header button' 'text image image';
		grid-template-columns: 2fr 2fr 1fr;
		row-gap: 0.5rem;
		column-gap: 0.5rem;
	}
	h1 {
		grid-area: header;
	}
	.descriptionBox {
		grid-area: text;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}
	.imageBox {
		grid-area: image;
	}
	.submit {
		grid-area: button;
		justify-self: end;
		align-self: center;
	}
	textarea {
		box-sizing: border-box;
		margin: 0;
		border: none;
		border-radius: 0.2rem;
		outline: none;
		width: 100%;
		border-bottom: 1px solid transparent;
		transition: all 0.1s ease-out;
		resize: none;
		flex: 1;
	}
	textarea:focus {
		border-bottom: 1px solid var(--primary);
	}
	button {
		background-color: var(--primary);
		border-radius: 50%;
		color: var(--primary-contrast);
		text-decoration: none;
		padding: 0.5rem;
		margin: 0.5rem;
		border: none;
		outline: none;
	}
</style>
