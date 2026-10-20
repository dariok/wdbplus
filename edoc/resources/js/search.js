$(() => {
  const base = wdb.meta.get('rest').get('2');
  
  let ed = wdb.parameters.get('ed')
    , q = wdb.parameters.get('q')
    , p = JSON.parse(decodeURIComponent(wdb.parameters.get('p')).replaceAll("'", '"'));
  
  if ( ed !== undefined && q !== undefined && p?.job == 'fts' && $('main div').children().length === 0 ) {
    $('aside div input[name=q]').first().val(q);
    let url = new URL(`search/ft/project/${ed}?q=${q}&p=${p}`, wdb.restUrl).toString();
    wdbDocument.loadContent(url, 'searchResults');
  }

  $('#fts').on('submit', ( event ) => {
    event.preventDefault();

    let ed = event.target.children.namedItem('ed')?.value
      , q = event.target.children.namedItem('q')?.value
      , p = event.target.children.namedItem('p')?.value; 

    let url = new URL(`search/ft/project/${ed}?q=${q}&p=${p}`, wdb.restUrl).toString();

    wdbDocument.loadContent(url, 'searchResults');
  });

  // a button for paginated results, e.g. of a full text search
  $('main').on('click', 'button[data-start]', ( event ) => {
    wdbDocument.loadContent(event.target.dataset.query + '&start=' + event.target.dataset.start, 'searchResults');
  });

  $(document).on('click', '.loadSearchResult', ( event ) => {
    wdbDocument.loadContent(event.target.dataset.link, event.target.dataset.file.toString(), event.target, 'div > dl');
  //   } else {
  //     wdbDocument.loadContent("", id, event.target);
  //   }
  });
});
