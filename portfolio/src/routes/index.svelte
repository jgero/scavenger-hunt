<script>
  import { onMount, onDestroy } from "svelte";
  import Landingpage from "../components/startpage-views/Landingpage.svelte";

  let fragment;
  const pages = ["#top", "#project_showcase", "#about_me", "#contact_me"];

  onMount(() => {
    window.addEventListener("hashchange", updateFragment);
    window.addEventListener("wheel", onScroll);
    fragment = window.location.hash;
  });

  onDestroy(() => {
    try {
      window.removeEventListener("hashchange", updateFragment);
      window.removeEventListener("wheel", onScroll);
    } catch (e) {
      fragment = undefined;
    }
  });

  function updateFragment() {
    fragment = window.location.hash;
  }

  function onScroll(ev) {
    const currentPageIndex = pages.findIndex((el) => el === fragment);
    if (ev.deltaY > 0) {
      // scroll down
      if (currentPageIndex === pages.length - 1) {
        // when already at the last page do nothing
        return;
      }
      window.location.hash = pages[currentPageIndex + 1];
    } else {
      // scroll up
      if (currentPageIndex === 0) {
        // when already at the first page do nothing
        return;
      }
      window.location.hash = pages[currentPageIndex - 1];
    }
  }
</script>

<style>
</style>

<svelte:head>
  <title>Sapper project template</title>
</svelte:head>

{#if fragment === '#top'}
  <Landingpage />
{:else if fragment === '#project_showcase'}
  <h1>project showcase</h1>
{:else if fragment === '#about_me'}
  <h1>about me</h1>
{:else if fragment === '#contact_me'}
  <h1>contact me</h1>
{/if}
