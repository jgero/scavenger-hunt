<script>
  import { fly } from "svelte/transition";
  import Clouds from "../Clouds.svelte";
</script>

<style>
  .container {
    display: grid;
    height: 100%;
    grid-template-columns: 2rem 1fr 3fr 2rem;
    grid-template-rows: 1fr 1fr 4fr 1fr;
    grid-template-areas: ". . . ." ". header . ." ". header clouds ." ". . . .";
  }
  h1,
  h2 {
    margin: 1rem 0;
  }

  header {
    grid-area: header;
    width: min-content;
    justify-self: center;
  }

  header > div {
    background-color: var(--dark-4);
    height: 2px;
    width: 100%;
  }

  figure {
    grid-area: clouds;
    margin: 0;
  }
</style>

<div class="container">
  <header>
    <h1 in:fly={{ x: -200, duration: 1500, delay: 800 }}>
      johannes
      <br />
      gerold
    </h1>
    <div in:fly={{ x: -200, duration: 1500, delay: 1000 }} />
    <h2 in:fly={{ x: -200, duration: 1500, delay: 1200 }}>
      web developer,
      <br />full stack.
    </h2>
  </header>
  <figure>
    <Clouds />
  </figure>
</div>
