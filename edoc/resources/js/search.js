$(() => {
  const base = wdb.meta.get('rest').get('2');

  $('#fts').on('submit', ( event ) => {
    event.preventDefault();

    let ed = event.target.children.namedItem('ed')?.value
      , q = event.target.children.namedItem('q')?.value
      , p = event.target.children.namedItem('p')?.value; 

    wdbDocument.loadContent(`${base}search/ft/project/${ed}?q=${q}&p=${p}`, 'searchResults', '<void/>');
  });

  $(document).on('click', '.loadSearchResult', ( event ) => {
    let id = event.target.dataset.target
      , q = event.target.dataset.query
      , p = JSON.parse(decodeURIComponent(wdb.parameters.p));
    
    if ( q !== undefined && p.job == 'fts' ) {
      wdbDocument.loadContent(wdb.meta.rest + 'search/file/' + id + '.html?q=' + q, id, event.target);
    } else if ( q !== undefined && ( p.job == 'search' || p.job == 'entries' ) ) {
      let url;
      
      if ( $(event.target).parents('ul').length == 1 ) {
         url = 'entities/collection/' + wdb.meta.ed + '/' + p.type + '/' + id + '.html';
      } else {
         url = 'entities/file/' + id + '/' + p.type + '/' + q + '.html';
      }
      
      wdbDocument.loadContent(wdb.meta.rest + url, id, event.target);
    } else {
      wdbDocument.loadContent("", id, event.target);
    }
  });
});
