<script>
import { onMount } from "svelte";
import { getLogger } from "../stores/debug-logger";

export let imageDataUrl;
export let altImageUrlPromise;

let fileChooserElement;
let logger;

onMount(() => {
    logger = getLogger();
})

function imageInputChanged() {
    if (!fileChooserElement.files || fileChooserElement.files.length !== 1){
        logger.log({
            logLevel: "error",
            message: "file does not exist or multiple were selected"
        });
        return;
    }
    const fr = new FileReader();
    fr.onload = (ev) => {
        imageDataUrl = ev.target.result;
        logger.log({
            logLevel: "log",
            message: "image is read"
        });
    }
    fr.readAsDataURL(fileChooserElement.files[0]);
}

</script>

<div class="wrapper">
	<div class="centeringBox">
		<label for="imgSelect" class="material-icons">photo_camera</label>
		<input id="imgSelect" on:change={imageInputChanged} bind:this={fileChooserElement} type="file" accept="image/*">
		{#if imageDataUrl}
			<img src={imageDataUrl} alt="user chosen file">
		{:else}
			{#await altImageUrlPromise()}
				<img src="images/placeholder.jpg" alt="missing">
			{:then url}
				{#if url}
					<img src={url} alt="stored file">
				{:else}
					<img src="images/placeholder.jpg" alt="missing">
				{/if}
			{/await}
		{/if}
	</div>
</div>


<style>
div.wrapper {
	height: 100%;
	width: 100%;
}
div.centeringBox {
	position: relative;
}
input {
	display: none;
}
label {
	position: absolute;
	bottom: 1rem;
	right: 1rem;
	font-size: 0.9rem;
    background-color: var(--primary);
    border-radius: 50%;
    color: var(--primary-contrast);
    text-decoration: none;
	padding: 0.5rem;
    border: none;
    outline: none;
}
img {
    max-width: 100%;
	border-radius: 0.5rem;
}
</style>

