<script>
  import { onMount } from "svelte";

  onMount(() => {
    document.addEventListener("mousemove", (ev) => {
      // calculate some deviation fraction from the center of the screen
      const heightPercentage =
        0.5 - Math.round((ev.screenY / window.innerHeight) * 100) / 100;
      const widthPercentage =
        0.5 - Math.round((ev.screenX / window.innerWidth) * 100) / 100;

      document
        .getElementById("solar-system")
        .style.setProperty(
          "transform",
          `rotateX(${heightPercentage * 45}deg) rotateY(${
            widthPercentage * 45
          }deg)`
        );
    });
  });
</script>

<style>
  figure {
    width: 600px;
    height: 300px;
    position: relative;
  }

  div[class^="orbit"] {
    border: 5px solid #d0d0d0;
    border-radius: 100% 50%;
    transform: rotate(-15deg);
    position: absolute;
  }
  .orbit-1 {
    height: 150px;
    width: 500px;
    top: 75px;
    left: 50px;
  }
  .orbit-2 {
    height: 130px;
    width: 400px;
    transform: rotate(-9deg) !important;
    top: 85px;
    left: 100px;
  }
  .orbit-3 {
    height: 100px;
    width: 280px;
    transform: rotate(-21deg) !important;
    top: 100px;
    left: 160px;
  }
  .orbit-4 {
    height: 70px;
    width: 210px;
    top: 115px;
    left: 195px;
  }

  .body {
    position: absolute;
    width: 15px;
    height: 15px;
    border-radius: 50%;
  }
  .body.sun {
    background-color: #ffc700;
    width: 25px;
    height: 25px;
    top: 140px;
    left: 292px;
  }
  .planet-1 {
    background-color: #6e7cfc;
    top: 194px;
    left: 262px;
  }
  .planet-2 {
    background-color: #ba00a7;
    top: 194px;
    left: 170px;
  }
  .planet-3 {
    background-color: #ff7a00;
    top: 80px;
    left: 484px;
  }
  .planet-4 {
    background-color: #449b00;
    width: 20px;
    height: 20px;
    top: 235px;
    left: 57px;
  }
</style>

<figure id="solar-system">
  <div class="orbit-1" />
  <div class="orbit-2" />
  <div class="orbit-3" />
  <div class="orbit-4" />
  <div class="body sun" />
  <div class="body planet-1" />
  <div class="body planet-2" />
  <div class="body planet-3" />
  <div class="body planet-4" />
</figure>
