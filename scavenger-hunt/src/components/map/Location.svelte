<script>
	import { getMap, getPositionOnMap } from '../../stores/map';
	import { getMyCoords } from '../../stores/my-coords';
	import { cubicOut } from 'svelte/easing';
	import { onMount } from 'svelte';
	import { fly, fade } from 'svelte/transition';

	export let location;
	export let mapRotation;
	export let popupState;
	export let markerState;

	let map, myCoords;

	onMount(() => {
		map = getMap();
		myCoords = getMyCoords();
	});

	function registerMarker(node) {
		// position of the marker has to be offset a bit so the tip of the marker points to the exact location on the map
		const unsubscribeMap = map.subscribe(() => {
			const absolutePosition = getPositionOnMap($map, location);
			node.setAttribute('x', absolutePosition.x - 12);
			node.setAttribute('y', absolutePosition.y - 24);
		});
		const unsubscribeRotation = mapRotation.subscribe((rotation) => {
			const absolutePosition = getPositionOnMap($map, location);
			node.setAttribute(
				'transform',
				`rotate(${360 - rotation}, ${absolutePosition.x}, ${
					absolutePosition.y
				})`
			);
		});
		return {
			destroy() {
				unsubscribeMap();
				unsubscribeRotation();
			},
		};
	}

	function drawDistanceLine(node) {
		const unsubscribeMap = map.subscribe(() => {
			if ($myCoords) {
				const circles = node.querySelectorAll('circle');
				const { x: x1, y: y1 } = getPositionOnMap($map, location);
				const { x: x2, y: y2 } = getPositionOnMap($map, $myCoords);
				circles[0].setAttribute('cx', x1);
				circles[0].setAttribute('cy', y1);
				circles[1].setAttribute('cx', x2);
				circles[1].setAttribute('cy', y2);
				const line = node.querySelector('line');
				line.setAttribute('x1', x1);
				line.setAttribute('y1', y1);
				line.setAttribute('x2', x2);
				line.setAttribute('y2', y2);
			}
		});
		return {
			destroy() {
				unsubscribeMap();
			},
		};
	}

	function openPopup(event, location) {
		if ($popupState.isVisible) {
			popupState.hide();
			setTimeout(() => {
				const x = event.clientX;
				const y = event.clientY;
				popupState.show({ x, y, data: location });
			}, 300);
		} else {
			const x = event.clientX;
			const y = event.clientY;
			popupState.show({ x, y, data: location });
		}
	}

	function dash(node, { duration }) {
		return {
			duration,
			css: (t) => {
				const eased = cubicOut(t);
				return `
 						stroke-dasharray: ${Math.ceil(node.getTotalLength())}px;
 						stroke-dashoffset: ${Math.ceil(node.getTotalLength()) * (eased - 1)};
					`;
			},
		};
	}
</script>

{#if $map}
	{#if $popupState.data === location}
		<g use:drawDistanceLine class="connector">
			<circle r="3" transition:fade={{ duration: 200 }} />
			<circle r="3" transition:fade={{ duration: 200 }} />
			<line id="connection" transition:dash={{ duration: 200 }} />
		</g>
	{/if}
	{#if markerState === 'next'}
		<use
			class="location"
			class:active={$popupState.data === location}
			use:registerMarker
			transition:fly={{ y: -40, duration: 200 }}
			on:click|stopPropagation={(event) => openPopup(event, location)}
			xlink:href="#location_questionmark"
		/>
	{:else if markerState === 'done'}
		<use
			class="location green"
			class:active={$popupState.data === location}
			use:registerMarker
			transition:fly={{ y: -40, duration: 200 }}
			on:click|stopPropagation={(event) => openPopup(event, location)}
			xlink:href="#location_check"
		/>
	{/if}
{/if}

<style>
	.location {
		transition: all 0.5s ease;
		fill: var(--font-color);
	}
	.location.active {
		fill: var(--primary);
	}
	.location.green {
		fill: var(--success-color);
	}
	.connector line {
		stroke: var(--font-color);
	}
	.connector circle {
		fill: var(--font-color);
	}
</style>
