<script>
    import firebase from 'firebase/app';
    import { onMount, onDestroy } from 'svelte';

    import RouteHeader from '../../components/RouteHeader.svelte';
    import ImageCapture from '../../components/ImageCapture.svelte';
    import { getLogger } from '../../stores/debug-logger';
    import { getMyCoords } from '../../stores/my-coords';
    import { getUserId } from '../../stores/user';

    let logger, myCoords, userId;
    let route, selectedPlace, form;
    let newImageDataUrl = "";

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
                            route = { lastEdit: new Date(), places: [] };
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
                            message: `could not fetch route data: ${JSON.stringify(
                                error
                            )}`,
                        });
                    }
                );
        });
    });

    async function savePlace() {
        const { name, latitude, longitude, id, description } = selectedPlace;
        if (form.checkValidity()) {
            route.lastEdit = new Date();
            let index = route.places.findIndex((el) => el.id === id);
            if (index >= 0) {
                route.places[index] = {
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
					description,
                    name,
                    id,
                };
            } else {
                route.places.push({
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
					description,
                    name,
                    id,
                });
            }
            await firebase
                .firestore()
                .collection('routes')
                .doc($userId)
                .set(route);
			if (newImageDataUrl) {
				await firebase.storage().ref().child(`${$userId}/${id}`).putString(newImageDataUrl,
					'data_url');
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

    async function deletePlace(place) {
        const { id } = place;
        route.places = route.places.filter((el) => el.id !== id);
        route.lastEdit = new Date();
        await firebase.firestore().collection('routes').doc($userId).set(route);
        logger.log({
            logLevel: 'log',
            message: 'updated places',
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
        selectedPlace.latitude = $myCoords.latitude;
        selectedPlace.longitude = $myCoords.longitude;
    }

    function setupNewLocation() {
        selectedPlace = {
            name: '',
			description: '',
            id: Math.random().toString().substr(2, 12),
        };
        if ($myCoords) {
            useCurrentLocation();
        } else {
            selectedPlace.latitude = '';
            selectedPlace.longitude = '';
        }
    }
	
	async function getImageForPlace(id) {
		let url = null;
		try {
            url = await firebase.storage().ref()
                            .child(`${$userId}/${id}`).getDownloadURL();
		} catch (e) {
			logger.log({
				logLevel: 'error',
				message: `could not fetch image: ${JSON.stringify(e)}`,
			});
		}
		return url;
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
	{#if route && route.places}
		<ul>
			<li>
				<h2>Stationen</h2>
				<button class="material-icons" on:click={setupNewLocation}>add</button>
			</li>
			{#each route.places as place}
				<li class:selected={selectedPlace && selectedPlace.id === place.id}>
					{place.name}
					<button on:click={() => (selectedPlace = place)} class="material-icons">edit</button>
				</li>
			{/each}
			<li>
				<h2>Teilnehmer: {route.searchers ? route.searchers.length : 0}</h2>
				<button class="material-icons" on:click={resetSearchers}>person_off</button>
			</li>
		</ul>
	{/if}

    {#if selectedPlace}
        <form on:submit|preventDefault={savePlace} bind:this={form}>
			<div class="buttonBox">
				<button type="button" class="material-icons" on:click={() => deletePlace(selectedPlace)}
					>delete</button
				>
				<button type="submit" class="material-icons">save</button>
				<button type="button" class="material-icons" on:click={() => ( selectedPlace = null
					)}>close</button>
			</div>
			<div class="titleBox">
				<label for="name">Name</label>
				<input
					id="name"
					type="text"
					bind:value={selectedPlace.name}
					required
					pattern="^[0-9a-zA-ZäöüÄÖÜß _-]*$"
				/>
			</div>
			<div class="descriptionBox">
				<label for="description">Beschreibung</label>
				<textarea
					id="description"
					bind:value={selectedPlace.description}
				/>
			</div>
			<div class="imageBox">
				<ImageCapture bind:imageDataUrl={newImageDataUrl}
					altImageUrlPromise={getImageForPlace} bind:imageId={selectedPlace.id} />
			</div>
			<div class="latBox">
				<label for="latitude">latitude</label>
				<input
					id="latitude"
					type="text"
					bind:value={selectedPlace.latitude}
					required
					pattern="^[0-9]*\.[0-9]*$"
				/>
			</div>
			<div class="lonBox">
				<label for="longitude">longitude</label>
				<input
					id="longitude"
					type="text"
					bind:value={selectedPlace.longitude}
					required
					pattern="^[0-9]*\.[0-9]*$"
					/>
			</div>
            {#if $myCoords}
				<div class="locationButtonBox">
					<button type="button" class="material-icons" on:click={useCurrentLocation}
						>near_me</button
					>
				</div>
            {/if}

        </form>
    {/if}
</main>

<style>
main {
    padding: 1rem;
	overflow: auto;
}
ul {
    margin: 0;
    padding: 0;
}
li:not(:first-child):not(:last-child) {
	padding-inline-start: 4rem;
}
li {
    display: flex;
    align-items: center;
    justify-content: space-between;
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
form input[type="text"],
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
form input[type="text"]:focus,
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
li:not(:first-child):not(:last-child) button{
	font-size: 0.9em;
	margin-inline-end: calc(0.5rem + 0.4rem);
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
