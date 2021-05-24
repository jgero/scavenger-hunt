<script>
    import firebase from 'firebase/app';
    import { onMount} from "svelte";
    import { getLogger } from '../stores/debug-logger';

    export let location, routeId;
    let imageUrl, logger;

    onMount(async () => {
        logger = getLogger();
        try {
            imageUrl = await firebase.storage().ref()
                            .child(`${routeId}/${location.id}`).getDownloadURL();
        } catch (e) {
            logger.log({
            logLevel: "error",
            message: `could not load image for location ${location.id}`
            }) 
        }
    });
</script>

<section>
    <h2>{location.name}</h2>
    <p>{location.description}</p>
    <img src={imageUrl} alt={location.name} />
</section>


<style>
section {
    overflow: auto;
    margin: 2rem 0;
}
img {
    max-width: 80vw;
}
</style>
