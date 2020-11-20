<script>
  import github from "images/github.png";
</script>

<style>
  ul {
    --space: 1em;
    margin: 0;
    padding: var(--space);
    display: flex;
    font-family: "Barlow Condensed", sans-serif;
    font-weight: 400;
  }

  li {
    list-style: none;
    text-transform: uppercase;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  li:first-child {
    margin-right: auto;
  }

  li:not(:first-child) {
    margin-inline-start: calc(2 * var(--space));
  }
</style>

<nav>
  <ul>
    <li><a href="/">johannes gerold</a></li>
    <li><a href="/#contact_me">contact me</a></li>
    <li>
      <a href="https://github.com/jgero" target="_blank">
        <img src={github} alt="github icon" />
      </a>
    </li>
  </ul>
</nav>
