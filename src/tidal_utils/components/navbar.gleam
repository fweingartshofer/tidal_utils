pub fn render() {
  "
<header class='nav'>
  <style>
    .nav-inner {
      display: flex;
      flex-direction: column;
    }
    
    /* Keep links structured */
    .nav-menu {
      display: flex;
      flex-direction: column;
    }
    
    /* Desktop layout */
    @media (min-width: 768px) {
      .nav-inner {
        flex-direction: row;
        align-items: center;
        justify-content: space-between;
      }
    
      .nav-menu {
        flex-direction: row;
      }
    }
  </style>
  <div class='nav-inner'>
    <div class='nav-brand'><a href='/'>Tidal Utils</a></div>

    <nav class='nav-menu'>
      <a href='/'>Home</a>
    </nav>
  </div>
</header>"
}
