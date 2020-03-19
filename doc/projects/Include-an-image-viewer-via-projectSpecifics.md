# Image Viewer

As an example how to use projectSpecifics and as a how-to for embedding a viewer, we will have a look at how to include the OpenSeaDragon viewer in your project or instance.

1. Images are usually displayed to the right. So we need to include the viewer in the right part of `view.html`, which is the element `aside` (on the basic page layout cf. [[main-html-files]]). To include the necessary files, we will create a footer here. A globally defined footer will live in `edoc/resource/rightFooter.html` while a project specific footer will be located in `edoc/data/yourProject/resource/projectRightFooter.html` or defined by a function `wdbPF:getProjectRightFooter`.
1. Create a JS file `osdviewer.js` for all functions necessary for the viewer in `edoc/resource` or ``edoc/data/yourProject/resource`:

        $.holdReady(true);
        var viewer = OpenSeadragon({
            preserveViewport: true,
            visibilityRatio: 1,
            minZoomLevel: 1,
            defaultZoomLevel: 1,
            id: "fac",
            sequenceMode: true,
            tileSources: []
        });
        
        id = $("meta[name='id']").attr("content");
        rest = $("meta[name='rest']").attr("content");
        $.get(rest + "resource/iiif/" + id + "/images", function(data){viewer.open(data);});
          
        viewer.addHandler('page', function(source, page, data){
          $('#pag' + (source.page + 1))[0].scrollIntoView();
        });
        viewer.addHandler('open', function() { $.holdReady(false); });

1. In this example, we create the HTML file with only one line:

        <script src="data/scripts/osdviewer.js"></script>
    
    Adjust the path in `@src` to point to where you stored the JS in the step before.
1. In a project’s `project.xqm` (or the global `project.xqm` for those projects without their own), load the main OpenSeadragon JS. Change `wdbPF:getProjectFiles` so it looks similar to this (of course you should keep `link` or `script` elements you already added):

        declare function wdbPF:getProjectFiles ( $model as map(*) ) as node()* {
          (
            <link rel="stylesheet" type="text/css" href="{wdb:getUrl($model?pathToEd || '/scripts/project.css')}" />,
            <script src="{wdb:getUrl($model?pathToEd || '/scripts/project.js')}" />,
            <script src="https://cdn.jsdelivr.net/npm/openseadragon@2.4/build/openseadragon/openseadragon.min.js"/>
          )
        };

1. In your  `project.js` overwrite `displayImage()` so that it sends the sequence number of the page to be displayed to OpenSeadragon, e.g.

        function displayImage(element) {
            let pbs = $('body').find('.pagebreak a');
            let pos = pbs.index(element);
            viewer.goToPage(pos);
        }

1. `osdviewer.js` created above makes use of the IIIF image descriptor endpoint of wdb+. For it to work, your TEI files need to have basic information about the images in a `facsimile` element, e.g.:

        <facsimile>
          <surface ulx="0" uly="0" lrx="978" lry="1500" xml:id="facs_1">
            <graphic url="https://yourserver.com/iiif/image.jpg" height="1500px" width="978px"/>
          </surface>
        </facsimile>

    This assumes that you have your images stored on a IIIF server. If that is the case, you should be done. If not, please read on.
1. If you do not have your images stored on a IIIF server, you can still specify images by URL as tile source(s). Let’s assume the image URLs are contained in an HTML `.pagebreak a`, attribute `@href`. In `osdviewer.js` from step 2 above, replace the line starting with `$.get` with

        let tiles = [];
        $('.pagebreak a').each(function(){
            let img = {
                type: 'image',
                url: $(this).attr('href')
            };
            tiles.push(img);
        });
        viewer.open(tiles);
