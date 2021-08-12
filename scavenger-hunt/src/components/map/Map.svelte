<script>
	import { onMount } from 'svelte';
	import { writable, derived } from 'svelte/store';
	import { getMyCoords } from '../../stores/my-coords';
	import { getLogger } from '../../stores/debug-logger';
	import { getUserId } from '../../stores/user';
	import { getMap } from '../../stores/map';

	import Popup from './Popup.svelte';
	import Location from './Location.svelte';
	import User from './User.svelte';

	// store for rotation
	const { subscribe: subscribeRotation, update: updateRotation } = writable(0);
	let mapRotation = {
		subscribe: subscribeRotation,
		setRotation: (newRotation) => updateRotation(() => newRotation),
	};
	// external stores
	let myCoords, logger, map, userId;

	// locations loaded from firestore
	export let locations, popupState;

	onMount(() => {
		myCoords = getMyCoords();
		logger = getLogger();
		map = getMap();
		userId = getUserId();
		// merge all the stores to update when data changes
		// the value of the store is just a random number because the value has to change to cause an emit
		const notifier = derived([locations, myCoords], () => Math.random());
		notifier.subscribe(() => {
			const l = [...$locations];
			if (l.length === 0) {
				return;
			}
			if ($myCoords) {
				l.push($myCoords);
			}
			map.updateCoordSystemFromLocations(l);
		});
	});

	function rotationGestureListener(node) {
		node.style.transform = `rotate(${$mapRotation}deg)`;
		let rotationStart, lastMeasurement;
		const mc = new Hammer.Manager(node, {
			recognizers: [[Hammer.Rotate]],
		});
		mc.on('rotatestart', (event) => {
			rotationStart = Math.floor(event.rotation);
		});
		mc.on('rotatemove', (event) => {
			let delta;
			if (lastMeasurement) {
				delta = Math.floor(event.rotation) - lastMeasurement;
				if (delta < 20 && delta > -20) {
					const newRoatation = $mapRotation + delta;
					mapRotation.setRotation(newRoatation % 360);
				}
			}
			lastMeasurement = Math.floor(event.rotation);
			node.style.transform = `rotate(${$mapRotation}deg)`;
		});
		mc.on('rotateend', (event) => {
			let delta = Math.floor(event.rotation) - rotationStart;
			logger.log({
				logLevel: 'log',
				message: `rotated map ${delta}° to ${$mapRotation}°`,
			});
		});
	}

	function getMarkerState(location) {
		if (location.solutions && location.solutions[$userId]) {
			return 'done';
		}
		const l = $locations;
		const currentIdex = l.findIndex((el) => el.id === location.id);
		const oneLocationBefore = l[currentIdex - 1];
		// check if it is the first location or the location before is alredy done
		if (
			currentIdex === 0 ||
			(oneLocationBefore.solutions && oneLocationBefore.solutions[$userId])
		) {
			return 'next';
		}
		return 'hidden';
	}
</script>

<div>
	{#if $map}
		<svg
			viewBox="0 0 {$map.outerSize} {$map.outerSize}"
			xmlns="http://www.w3.org/2000/svg"
			id="overlay"
		>
			<line
				x1={($map.outerSize - $map.kmLengthOnMap) / 2}
				y1={$map.outerSize - 0.3 * $map.padding - 2}
				x2={($map.outerSize - $map.kmLengthOnMap) / 2}
				y2={$map.outerSize - 0.3 * $map.padding + 2}
				stroke="black"
			/>
			<line
				x1={($map.outerSize - $map.kmLengthOnMap) / 2}
				y1={$map.outerSize - 0.3 * $map.padding}
				x2={$map.outerSize - ($map.outerSize - $map.kmLengthOnMap) / 2}
				y2={$map.outerSize - 0.3 * $map.padding}
				stroke="black"
			/>
			<text
				x={$map.outerSize / 2}
				y={$map.outerSize - 0.3 * $map.padding + 10}
				text-anchor="middle"
				font-size="10"
			>
				1km
			</text>
			<line
				x1={$map.outerSize - ($map.outerSize - $map.kmLengthOnMap) / 2}
				y1={$map.outerSize - 0.3 * $map.padding - 2}
				x2={$map.outerSize - ($map.outerSize - $map.kmLengthOnMap) / 2}
				y2={$map.outerSize - 0.3 * $map.padding + 2}
				stroke="black"
			/>
		</svg>
		<svg
			viewBox="0 0 {$map.outerSize} {$map.outerSize}"
			xmlns="http://www.w3.org/2000/svg"
			use:rotationGestureListener
		>
			<defs>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					height="24"
					viewBox="0 0 24 24"
					width="24px"
					id="location_check"
					><path d="M0 0h24v24H0V0z" fill="none" /><path
						d="M12 2c3.86 0 7 3.14 7 7 0 5.25-7 13-7 13S5 14.25 5 9c0-3.86 3.14-7 7-7zm-1.53 12L17 7.41 15.6 6l-5.13 5.18L8.4 9.09 7 10.5l3.47 3.5z"
					/></svg
				>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					height="24"
					viewBox="0 0 24 24"
					width="24"
					id="location_questionmark"
					><path d="M0 0h24v24H0V0z" fill="none" /><path
						d="M12 2C8.14 2 5 5.14 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.86-3.14-7-7-7zm.88 13.75h-1.75V14h1.75v1.75zm0-2.87h-1.75c0-2.84 2.62-2.62 2.62-4.38 0-.96-.79-1.75-1.75-1.75s-1.75.79-1.75 1.75H8.5C8.5 6.57 10.07 5 12 5s3.5 1.57 3.5 3.5c0 2.19-2.62 2.41-2.62 4.38z"
					/></svg
				>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					height="24"
					viewBox="0 0 24 24"
					width="24"
					id="location"
					><path d="M0 0h24v24H0z" fill="none" />
					<path
						d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"
					/></svg
				>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					enable-background="new 0 0 24 24"
					height="24"
					viewBox="0 0 24 24"
					width="24"
					id="user"
					><g>
						<rect fill="none" height="24" width="24" />
					</g>
					<g>
						<g>
							<g>
								<path
									d="M12,2C8.14,2,5,5.14,5,9c0,5.25,7,13,7,13s7-7.75,7-13C19,5.14,15.86,2,12,2z M12,4c1.1,0,2,0.9,2,2c0,1.11-0.9,2-2,2 s-2-0.89-2-2C10,4.9,10.9,4,12,4z M12,14c-1.67,0-3.14-0.85-4-2.15c0.02-1.32,2.67-2.05,4-2.05s3.98,0.73,4,2.05 C15.14,13.15,13.67,14,12,14z"
								/>
							</g>
						</g>
					</g></svg
				>
			</defs>
			<g>
				{#each $locations as location}
					<Location
						{location}
						{mapRotation}
						{popupState}
						markerState={getMarkerState(location)}
					/>
				{/each}
				<User {mapRotation} />
			</g>
		</svg>
	{/if}
</div>
<Popup {popupState} />

<style>
	div {
		position: relative;
		width: 100%;
		overflow: hidden;
		border-radius: 0.6rem;
		box-shadow: -2px -2px 4px 0px #ffffff, 2px 2px 4px 0px #00000025;
	}
	#overlay {
		position: absolute;
		top: 0;
		left: 0;
	}
</style>
