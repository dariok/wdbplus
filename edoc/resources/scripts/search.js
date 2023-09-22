$(() => {
  $(document).on('click', '.loadSearchResult', ( event ) => {
    let id = event.target.dataset.target
      , q = event.target.dataset.query
      , p = JSON.parse(decodeURI(wdb.parameters.p));
    
    if ( q !== undefined && p.job == 'fts' ) {
      wdbDocument.loadContent(wdb.meta.rest + 'search/file/' + id + '.html?q=' + q, id, event.target);
    } else if ( q !== undefined && p.job == 'search' ) {
      wdbDocument.loadContent(wdb.meta.rest + 'entities/collection/' + wdb.meta.ed + '/' + p.type + '/' + id + '.html', id, event.target);
    } else {
      wdbDocument.loadContent("", id, event.target);
    }
  });
});
