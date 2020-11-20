<script>
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
    overflow: hidden;
  }
</style>

<div class="container">
  <header>
    <h1>johannes <br /> gerold</h1>
    <div />
    <h2>web developer, <br />full stack.</h2>
  </header>
  <figure>
    <Clouds />
  </figure>
</div>
