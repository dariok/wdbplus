$(() => {
  $(document).on('click', '.loadSearchResult', ( event ) => {
    let id = event.target.dataset.target
      , q = event.target.dataset.query;
    if ( q !== undefined ) {
      wdbDocument.loadContent(wdb.meta.rest + 'search/file/' + id + '.html?q=' + q, id, event.target);
    } else {
      wdbDocument.loadContent("", id, event.target);
    }
  });
});
