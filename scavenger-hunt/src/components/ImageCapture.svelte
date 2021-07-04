<script>
import firebase from 'firebase/app';
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

<style>
input {
	display: none;
}
img {
    max-width: 100%
}
</style>

