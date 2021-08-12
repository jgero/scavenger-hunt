<script>
	import firebase from 'firebase/app';
	import { onMount, onDestroy } from 'svelte';

	import RouteHeader from '../../components/RouteHeader.svelte';
	import ImageCapture from '../../components/ImageCapture.svelte';
	import { getLogger } from '../../stores/debug-logger';
	import { getMyCoords } from '../../stores/my-coords';
	import { getUserId } from '../../stores/user';

	let logger, myCoords, userId;
	let route, selectedLocation, form;
	let newImageDataUrl = '';

	let latInputEl, lonInputEl;

	let unsubSnapshotListener;
	let unsubscribe;

	onMount(() => {
		logger = getLogger();
		myCoords = getMyCoords();
		userId = getUserId();

		unsubscribe = userId.subscribe((uid) => {
			if (!uid) {
				return;
			}
			unsubSnapshotListener = firebase
				.firestore()
				.collection('routes')
				.doc(uid)
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
							message: `route of user ${uid} loaded`,
						});
						route = snapshot.data();
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

	async function saveLocation() {
		const { name, latitude, longitude, id, description } = selectedLocation;
		if (form.checkValidity()) {
			route.lastEdit = new Date();
			let index = route.locations.findIndex((el) => el.id === id);
			if (index >= 0) {
				route.locations[index] = {
					latitude: parseFloat(latitude),
					longitude: parseFloat(longitude),
					description,
					name,
					id,
				};
			} else {
				route.locations.push({
					latitude: parseFloat(latitude),
					longitude: parseFloat(longitude),
					description,
					name,
					id,
				});
			}
			await firebase.firestore().collection('routes').doc($userId).set(route);
			if (newImageDataUrl) {
				await firebase
					.storage()
					.ref()
					.child(`${$userId}/${id}`)
					.putString(newImageDataUrl, 'data_url');
			}
			logger.log({
				logLevel: 'log',
				message: `route updated`,
			});
		} else {
			logger.log({
				logLevel: 'error',
				message: `invalid fields`,
			});
		}
	}

	async function deleteLocation(location) {
		const { id } = location;
		route.locations = route.locations.filter((el) => el.id !== id);
		route.lastEdit = new Date();
		await firebase.firestore().collection('routes').doc($userId).set(route);
		logger.log({
			logLevel: 'log',
			message: 'updated locations',
		});
	}

	async function moveLocationUp(index) {
		[route.locations[index], route.locations[index - 1]] = [
			route.locations[index - 1],
			route.locations[index],
		];
		route.lastEdit = new Date();
		await firebase.firestore().collection('routes').doc($userId).set(route);
		logger.log({
			logLevel: 'log',
			message: 'updated location order',
		});
	}
	async function moveLocationDown(index) {
		[route.locations[index], route.locations[index + 1]] = [
			route.locations[index + 1],
			route.locations[index],
		];
		route.lastEdit = new Date();
		await firebase.firestore().collection('routes').doc($userId).set(route);
		logger.log({
			logLevel: 'log',
			message: 'updated location order',
		});
	}

	async function resetSearchers() {
		route.searchers = [];
		await firebase.firestore().collection('routes').doc($userId).set(route);
		logger.log({
			logLevel: 'log',
			message: 'reset searchers',
		});
	}

	function useCurrentLocation() {
		selectedLocation.latitude = $myCoords.latitude;
		selectedLocation.longitude = $myCoords.longitude;
	}

	function setupNewLocation() {
		selectedLocation = {
			name: '',
			description: '',
			id: Math.random().toString().substr(2, 12),
		};
		if ($myCoords) {
			useCurrentLocation();
		} else {
			selectedLocation.latitude = '';
			selectedLocation.longitude = '';
		}
	}

	async function getImageForLocation() {
		let url = null;
		try {
			url = await firebase
				.storage()
				.ref()
				.child(`${$userId}/${selectedLocation.id}`)
				.getDownloadURL();
		} catch (e) {
			logger.log({
				logLevel: 'error',
				message: `could not fetch image: ${JSON.stringify(e)}`,
			});
		}
		return url;
	}

	function coordsInputChanged(ev) {
		// handle copy paste from google maps coordinates into cords fields
		const input = ev.data;
		const regex = new RegExp(
			'^[0-9]{1,2}(.[0-9]+){0,1}, [0-9]{1,2}(.[0-9]+){0,1}$'
		);
		// don't autofill if both fields have text or regex does not match
		if (
			(selectedLocation.latitude != '' && selectedLocation.longitude != '') ||
			!regex.test(input)
		) {
			return;
		}
		let [lat, lon] = input.split(' ');
		lat = lat.substring(0, lat.indexOf(','));
		selectedLocation.latitude = lat;
		selectedLocation.longitude = lon;
	}

	onDestroy(() => {
		if (unsubSnapshotListener) {
			unsubSnapshotListener();
		}
		if (unsubscribe) {
			unsubscribe();
		}
	});
</script>

<RouteHeader title="Route bearbeiten" />

<main>
	{#if route && route.locations}
		<ol type="1">
			<li>
				<h2>Stationen</h2>
				<button class="material-icons" on:click={setupNewLocation}>add</button>
			</li>
			{#each route.locations as location, index}
				<li
					class:selected={selectedLocation &&
						selectedLocation.id === location.id}
				>
					{location.name}
					<div>
						<button
							on:click={() => moveLocationUp(index)}
							class="material-icons"
							disabled={index === 0}>arrow_upward</button
						>
						<button
							on:click={() => moveLocationDown(index)}
							class="material-icons"
							disabled={index >= route.locations.length - 1}
							>arrow_downward</button
						>
						<button
							on:click={() => (selectedLocation = location)}
							class="material-icons">edit</button
						>
					</div>
				</li>
			{/each}
			<li>
				<h2>
					Teilnehmer: {route.searchers ? route.searchers.length : 0}
				</h2>
				<button class="material-icons" on:click={resetSearchers}
					>person_off</button
				>
			</li>
		</ol>
	{/if}

	{#if selectedLocation}
		<form on:submit|preventDefault={saveLocation} bind:this={form}>
			<div class="buttonBox">
				<button
					type="button"
					class="material-icons"
					on:click={() => deleteLocation(selectedLocation)}>delete</button
				>
				<button type="submit" class="material-icons">save</button>
				<button
					type="button"
					class="material-icons"
					on:click={() => (selectedLocation = null)}>close</button
				>
			</div>
			<div class="titleBox">
				<label for="name">Name</label>
				<input
					id="name"
					type="text"
					bind:value={selectedLocation.name}
					required
					pattern="^[0-9a-zA-ZäöüÄÖÜß _-]*$"
				/>
			</div>
			<div class="descriptionBox">
				<label for="description">Beschreibung</label>
				<textarea id="description" bind:value={selectedLocation.description} />
			</div>
			<div class="imageBox">
				<ImageCapture
					bind:imageDataUrl={newImageDataUrl}
					altImageUrlPromise={getImageForLocation}
				/>
			</div>
			<div class="latBox">
				<label for="latitude">latitude</label>
				<input
					id="latitude"
					type="text"
					bind:value={selectedLocation.latitude}
					bind:this={latInputEl}
					on:input={coordsInputChanged}
					required
					pattern="^[0-9]*\.[0-9]*$"
				/>
			</div>
			<div class="lonBox">
				<label for="longitude">longitude</label>
				<input
					id="longitude"
					type="text"
					bind:value={selectedLocation.longitude}
					bind:this={lonInputEl}
					on:input={coordsInputChanged}
					required
					pattern="^[0-9]*\.[0-9]*$"
				/>
			</div>
			{#if $myCoords}
				<div class="locationButtonBox">
					<button
						type="button"
						class="material-icons"
						on:click={useCurrentLocation}>near_me</button
					>
				</div>
			{/if}
		</form>
	{/if}
	<a href="/results/{$userId}">Lösungen ansehen</a>
</main>

<style>
	main {
		padding: 1rem;
		overflow: auto;
	}
	ol {
		margin: 0;
		padding: 0;
		counter-reset: locations;
	}
	li:not(:first-child):not(:last-child) {
		padding-inline-start: 4rem;
		position: relative;
	}
	li:not(:first-child):not(:last-child)::before {
		position: absolute;
		right: calc(100% - 3.5rem);
		counter-increment: locations;
		content: counter(locations) '. ';
	}
	li {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-block-end: 1rem;
		padding-left: 1.5rem;
	}
	li.selected {
		background-color: rgba(0, 0, 0, 0.05);
		border-radius: 0.5rem;
	}
	form {
		display: grid;
		grid-template-rows: auto 1fr 3fr 1fr;
		grid-template-columns: 4fr 4fr 2fr;
		grid-template-areas:
			'buttons buttons buttons'
			'title image image'
			'description image image'
			'lat lon locationButton';
		grid-row-gap: 1rem;
		grid-column-gap: 1rem;
		border-radius: 0.6rem;
		box-shadow: -2px -2px 4px 0px #ffffff, 2px 2px 4px 0px #00000025;
		padding: 0.5rem;
	}
	form > div {
		overflow: hidden;
		display: flex;
		flex-direction: column;
	}
	form label {
		font-size: 0.8rem;
	}
	form input[type='text'],
	form textarea {
		box-sizing: border-box;
		margin: 0;
		border: none;
		border-radius: 0.2rem;
		outline: none;
		width: 100%;
		border-bottom: 1px solid transparent;
		transition: all 0.1s ease-out;
	}
	form textarea {
		resize: none;
		flex: 1;
	}
	form input[type='text']:focus,
	form textarea:focus {
		border-bottom: 1px solid var(--primary);
	}
	form > div.buttonBox {
		display: flex;
		flex-direction: row;
		justify-content: flex-end;
		grid-area: buttons;
	}
	form .buttonBox button {
		font-size: 0.9rem;
		margin: 0;
		margin-inline-start: 0.5rem;
	}
	form .titleBox {
		grid-area: title;
	}
	form .descriptionBox {
		grid-area: description;
	}
	form .imageBox {
		grid-area: image;
	}
	form .latBox {
		grid-area: lat;
	}
	form .lonBox {
		grid-area: lon;
	}
	form .locationButtonBox {
		grid-area: locationButton;
		justify-self: end;
		align-self: end;
	}
	form .locationButtonBox button {
		font-size: 0.9rem;
		padding: 0.5rem;
		margin: 0;
	}
	li:not(:first-child):not(:last-child) div {
		margin-inline-end: calc(0.5rem + 0.4rem);
	}
	li:not(:first-child):not(:last-child) button {
		font-size: 0.9em;
		margin-inline: 0.1rem;
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
	button:disabled {
		opacity: 0.4;
	}
	a {
		background-color: var(--success-color);
		border-radius: 0.6rem;
		color: var(--primary-contrast);
		text-decoration: none;
		padding: 0.5rem;
		display: block;
		margin-inline-start: auto;
		margin-block-start: 1rem;
		width: max-content;
	}
</style>
