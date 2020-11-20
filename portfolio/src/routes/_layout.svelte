<script>
  import Nav from "../components/Nav.svelte";
  import Sidebar from "../components/Sidebar.svelte";
</script>

<style>
  main {
    display: flex;
    height: 100%;
    overflow: hidden;
  }

  div {
    flex: 1;
  }
</style>

<Nav />

<main>
  <Sidebar />
  <div>
    <slot />
  </div>
</main>
