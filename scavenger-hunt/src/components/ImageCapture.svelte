<script>
import { onMount } from "svelte";
import { getLogger } from "../stores/debug-logger";

export let imageDataUrl;

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

<input on:change={imageInputChanged} bind:this={fileChooserElement} type="file" accept="image/*">
{#if imageDataUrl}
    <img src={imageDataUrl} alt="user chosen file">
{/if}

<style>
img {
    max-width: 100%
}
</style>

