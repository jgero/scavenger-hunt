<script context="module">
	export async function preload({ params }) {
		return { routeId: params.routeId };
	}
</script>

<script>
	import firebase from 'firebase/app';
	import { onMount, onDestroy } from 'svelte';
	import { writable } from 'svelte/store';
	import { getLogger } from '../../../stores/debug-logger';

	import RouteHeader from '../../../components/RouteHeader.svelte';
	import Map from '../../../components/map/Map.svelte';
	import LocationDetails from '../../../components/LocationDetails.svelte';

	export let routeId;

	let logger;
	const locations = writable([]);
	let unsubSnapshotListener;

	// store for popup state
	const { subscribe: subscribePopup, update: updatePopup } = writable({
		x: 0,
		y: 0,
		isVisible: false,
		data: {},
	});
	let popupState = {
		subscribe: subscribePopup,
		show: ({ x, y, data }) =>
			updatePopup(() => ({ x, y, isVisible: true, data })),
		hide: () => updatePopup(() => ({ x: 0, y: 0, isVisible: false, data: {} })),
	};

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
					locations.update(() => doc.data().locations);
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
</script>

<RouteHeader title={'Finde die Stationen!'} />
<main>
	<Map {locations} {popupState} />
	{#if $popupState.isVisible}
		<LocationDetails location={$popupState.data} {routeId} />
	{/if}
</main>

<style>
	main {
		width: 100%;
		overflow: hidden;
		padding: 1rem;
		box-sizing: border-box;
		display: flex;
		flex-direction: column;
	}
</style>
