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
    let newImageDataUrl;

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
        const { name, latitude, longitude, id } = selectedPlace;
        if (form.checkValidity()) {
            route.lastEdit = new Date();
            let index = route.places.findIndex((el) => el.id === id);
            if (index >= 0) {
                route.places[index] = {
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
                    name,
                    id,
                };
            } else {
                route.places.push({
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
                    name,
                    id,
                });
            }
            await firebase
                .firestore()
                .collection('routes')
                .doc($userId)
                .set(route);
                console.log(newImageDataUrl)
            await firebase.storage().ref().child(`${$userId}/${id}`).putString(newImageDataUrl,
            'data_url');
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
            id: Math.random().toString().substr(2, 12),
        };
        if ($myCoords) {
            useCurrentLocation();
        } else {
            selectedPlace.latitude = '';
            selectedPlace.longitude = '';
        }
    }

	async function getImageForPlace() {
		let url = null;
		try {
            url = await firebase.storage().ref()
                            .child(`${$userId}/${selectedPlace.id}`).getDownloadURL();
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
    <h2>Stationen:</h2>
    <ul>
        {#each route.places as place}
            <li on:click={() => (selectedPlace = place)} class:selected={selectedPlace && selectedPlace.id ===
                    place.id}>
                {place.name}
                <button on:click={() => (selectedPlace = place)}><span
                        class="material-icons">edit</span></button>
            </li>
        {/each}
        <li><button class="align-left"  on:click={setupNewLocation}><span class="material-icons">add</span></button></li>
    </ul>

    <section>
        <div>
    <h2>Teilnehmer: {route.searchers ? route.searchers.length : 0}</h2>
    <button on:click={resetSearchers}><span class="material-icons">clear</span> RESET</button>
            </div>
        <p>Scanne den QR-Code von den Mitspielern um sie deiner Route hinzuzufügen.</p>
        </section>
{/if}

    {#if selectedPlace}
        <form on:submit|preventDefault={savePlace} bind:this={form}>
            <input
                id="name"
                type="text"
                bind:value={selectedPlace.name}
                required
                pattern="^[0-9a-zA-ZäöüÄÖÜß _-]*$"
            />
            <label for="latitude">latitude</label>
            <input
                id="latitude"
                type="text"
                bind:value={selectedPlace.latitude}
                required
                pattern="^[0-9]*\.[0-9]*$"
            />
            <label for="longitude">longitude</label>
            <input
                id="longitude"
                type="text"
                bind:value={selectedPlace.longitude}
                required
                pattern="^[0-9]*\.[0-9]*$"
				/>

            <ImageCapture bind:imageDataUrl={newImageDataUrl} altImageUrlPromise={getImageForPlace} />
            <button type="submit">SAVE</button>
            <button type="button" on:click={() => ( selectedPlace = null )}>CLOSE</button>
                <button type="button" on:click={() => deletePlace(selectedPlace)}
                    >DELETE</button
                >
            {#if $myCoords}
                <button type="button" on:click={useCurrentLocation}
                    >USE MY LOCATION</button
                >
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

section div {
display: flex;
align-items: center;
justify-content: space-between;
}
section div button {
    height: min-content;
}
    li {
        display: flex;
        align-items: center;
        justify-content: space-between;
    padding-left: 1.5rem;
}
 
button.align-left {
margin-left: 0;
}
    form {
        display: grid;
        grid-template-rows: 2fr 1fr 1fr;
        grid-template-columns: 25% 75%;
        grid-template-areas: 'h h' 'latn latc' 'lonn lonc';
        border-radius: 0.6rem;
        box-shadow: -2px -2px 4px 0px #ffffff, 2px 2px 4px 0px #00000025;
    padding: 1rem;
    }
    form #name {
        font-size: 2rem;
        grid-area: h;
    }
button {
    background-color: var(--primary);
    border-radius: 6px;
    color: white;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    width: max-content;
    padding: 0.2rem 1rem;
    margin: 0.5rem;
    border: none;
    outline: none;
}
    button span {
        margin-right: 0.2rem;
    }
</style>
