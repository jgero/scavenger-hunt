<script context="module">
	export async function preload({ params }) {
		return { routeId: params.routeId };
	}
</script>

<script>
	import firebase from 'firebase/app';
	import { onMount, onDestroy } from 'svelte';

	import { getLogger } from '../../stores/debug-logger';

	import RouteHeader from '../../components/RouteHeader.svelte';

	export let routeId;
	let unsubSnapshotListener, route, selectedLocation, logger, solutions;

	const additionalButtons = [{ value: 'arrow_back', href: '/create' }];

	onMount(() => {
		logger = getLogger();

		unsubSnapshotListener = firebase
			.firestore()
			.collection('routes')
			.doc(routeId)
			.onSnapshot(
				(snapshot) => {
					if (snapshot.empty || !snapshot.data()) {
						logger.log({
							logLevel: 'log',
							message: 'snapshot of my route is empty',
						});
						route = { lastEdit: new Date(), locations: [] };
						return;
					}
					logger.log({
						logLevel: 'log',
						message: `route of user ${routeId} loaded`,
					});
					route = snapshot.data();
					if (route.locations.length > 0) {
						selectedLocation = route.locations[0];
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

	$: {
		if (!selectedLocation || !selectedLocation.solutions) {
			solutions = [];
		} else {
			let arr = Object.keys(selectedLocation.solutions).map((key) => ({
				userId: key,
				...selectedLocation.solutions[key],
			}));
			solutions = arr.length > 0 ? arr : [];
		}
	}

	async function getSolutionImageUrl(solution) {
		let url = null;
		try {
			url = await firebase
				.storage()
				.ref()
				.child(`${routeId}/${selectedLocation.id}/${solution.userId}`)
				.getDownloadURL();
		} catch (e) {
			logger.log({
				logLevel: 'error',
				message: `could not load image for location ${location.id}`,
			});
		}
		return url;
	}
</script>

<RouteHeader title="Lösungen" {additionalButtons} />

<main>
	<ol type="1">
		<li>
			<h2>Stationen</h2>
		</li>
		{#if route}
			{#each route.locations as location}
				<li
					class:selected={selectedLocation &&
						selectedLocation.id === location.id}
					on:click={() => (selectedLocation = location)}
				>
					{location.name}
				</li>
			{/each}
		{/if}
	</ol>
	<ul>
		<li>
			<h2>Lösungen</h2>
		</li>
		{#each solutions as solution}
			<li class="solution">
				<span>{solution.solutionText}</span>
				{#if solution.hasImage}
					{#await getSolutionImageUrl(solution)}
						<span>loading image...</span>
					{:then url}
						<img src={url} alt="proof" />
					{/await}
				{/if}
			</li>
		{/each}
	</ul>
</main>

<style>
	main {
		padding: 1rem;
		overflow: auto;
	}
	ol,
	ul {
		margin: 0;
		padding: 0;
		counter-reset: locations;
	}
	li:not(:first-child) {
		padding-inline-start: 4rem;
		position: relative;
	}
	ol li:not(:first-child)::before {
		position: absolute;
		right: calc(100% - 3.5rem);
		counter-increment: locations;
		content: counter(locations) '. ';
	}
	li {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.5rem;
		padding-left: 1.5rem;
		margin-bottom: 0.5rem;
	}
	li.selected {
		background-color: rgba(0, 0, 0, 0.05);
		border-radius: 0.5rem;
	}
	li.solution {
		flex-direction: column;
	}
	li img {
		max-width: 100%;
		border-radius: 0.6rem;
		margin-block-start: 1rem;
	}
	li.solution::after {
		content: '';
		position: absolute;
		height: 1px;
		background-color: var(--font-color);
		width: calc(100% - 1.5rem - 0.5rem);
		bottom: 0;
		left: 1.5rem;
		opacity: 0.1;
	}
</style>
