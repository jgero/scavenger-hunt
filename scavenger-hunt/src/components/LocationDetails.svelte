<script>
	import firebase from 'firebase/app';
	import { onMount, onDestroy } from 'svelte';
	import { getLogger } from '../stores/debug-logger';
	import { getMyCoords } from '../stores/my-coords';
	import { getUserId } from '../stores/user';
	import { getDistanceFromLatLonInKm } from '../utils/coordinates-to-meters.js';

	export let location, routeId;
	let imageUrl, logger, myCoords, userId;
	let distance = '?? km',
		canSubmit = false,
		unsubCoords;

	onMount(() => {
		logger = getLogger();
		myCoords = getMyCoords();
		userId = getUserId();
		loadImage();
		unsubCoords = myCoords.subscribe((coords) => {
			if (coords) {
				distance =
					Math.round(
						getDistanceFromLatLonInKm(
							coords.latitude,
							coords.longitude,
							location.latitude,
							location.longitude
						) * 10
					) / 10;
				// accuracy is provided in meters so it needs / 1000
				// user can submit if he is closer than 50 meters after subtracting the accuracy
				canSubmit = distance - coords.accuracy / 1000 < 0.05;
			} else {
				distance == '??';
				canSubmit = false;
			}
		});
	});

	async function loadImage() {
		try {
			imageUrl = await firebase
				.storage()
				.ref()
				.child(`${routeId}/${location.id}`)
				.getDownloadURL();
		} catch (e) {
			logger.log({
				logLevel: 'error',
				message: `could not load image for location ${location.id}`,
			});
		}
	}

	onDestroy(() => {
		unsubCoords();
	});
</script>

<section>
	<h2>{location.name} ({distance} km)</h2>
	<p>{location.description}</p>
	<img src={imageUrl} alt={location.name} />
	<a href="/join/{routeId}/{location.id}/{$userId}" disabled={!canSubmit}
		>Ort gefunden</a
	>
</section>

<style>
	section {
		overflow: auto;
		margin: 2rem 0;
		display: grid;
		grid-template-areas: 'title title' 'description image' 'button button';
		grid-template-columns: 2fr 3fr;
		column-gap: 0.5rem;
		row-gap: 0.5rem;
		grid-template-rows: auto auto auto;
		color: var(--font-color);
	}
	section > * {
		margin: 0;
	}
	h2 {
		grid-area: title;
	}
	p {
		grid-area: description;
	}
	img {
		grid-area: image;
		width: 100%;
		border-radius: 0.6rem;
	}
	a {
		grid-area: button;
		background-color: var(--success-color);
		border-radius: 0.6rem;
		color: var(--primary-contrast);
		text-decoration: none;
		padding: 0.5rem;
		width: max-content;
		justify-self: end;
	}
	a[disabled] {
		pointer-events: none;
		opacity: 0.4;
	}
</style>
