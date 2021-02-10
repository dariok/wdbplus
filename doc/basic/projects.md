## Project
A **project** is any set of collections (i. e. editions) “held together“ by a shared `project.xqm`. In terms of database
structure, all elements of this set MUST be subcollections of the collection holding the common `project.xqm`. This
`project.xqm` is shared by all children (but may be overwritten); a project SHOULD have a `wdbmeta.xml` of it own.

## Collection
A **Collection** (usually one edition or one phase phase of a longer project) is always identified by its
[[wdbmeta.xml]]. A Collection always lives in an eXist-collection of its own. It may have children: these need to live
in an eXist sub-collection and MUST have a `wdbmeta.xml` of their own. It is also possible to have further eXist
sub-collections without `wdbmeta.xml` to bring order to the chaos of larger projects. These are not considered to be a
Collection in their own right. Each Collection is identified by the value of `projectMD/@xml:id` in its `wdbmeta.xml`.
Hence, this value MUST be globally unique. This is not enforced, though, as importing projects, e. g. via git, may
introduce duplicates that are more easily identified and handled from within the DB.

## Resource
While a resource can be anything that is stored in the DB, this term is narrowed down here. A Resource is anything that
is identified by an ID in a `wdbmeta.xml`. This includes that file itself and usually every XML file that is intended to
be displayed. In this case, the value of `file/@xml:id` in `wdbmeta.xml` MUST be equal to the value of `@xml:id` on the
top level element of the XML file, e. g. `doc('wdbmeta.xml')//file/@xml:id = doc('tei.xml')/TEI/@xml:id`. Access to
Resources is by their ID, be that for any retrieval via [[REST|REST-endpoints]] or for display via `view.html`. Hence, a
file’s ID MUST be globally unique. Again, this is not enforced but an error will be generated if more than one resource
is found with any given ID.