# W. Digitale Bibliothek (wdbplus)

An extensible framework for digital Editions for the [eXist XML database](https://github.com/eXist-db).

This framework still lacks a good name. If you have an idea, please let me know!

## Currently used in these projects:

* HAB Wolfenbüttel
  * Editionsprojekt Karlstadt
* ACDH Wien
  * Wien[n]erisches Diarium Digital
  * Repertotium frühneuzeitlicher Rechtsquellen
  * Protokolle der Sitzungen der Gesamtakadmie
* Akademie der Wissenschaften, Heidelberg
    * Theologenbriefwechsel

If you use wdbplus for your editions, please drop me a message so I can add you to this list.

## Building the documentation

To build the documentation, set up a virtual environment and install sphinx with `pip`. You only need to this once and it does no harm to your system.
    ```
    python3 -m venv .env
    source .env/bin/activate
    pip install -r requirements-doc.txt
    ```
To build the documentation, make sure to have your virtual environment enabled.
    ```
    source .env/bin/activate
    ```
Then go to `doc` and simply call
    ```
    make html
    ```
Your new build documentation is in `doc/_build/html` and you can view it with your favourite browser.
