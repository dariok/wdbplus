============
Contribution
============


Building the documentation
==========================

To build the documentation, set up a virtual environment and install sphinx with `pip`. You only need to this once and it does no harm to your system.
    
.. code-block:: none

    python3 -m venv .env
    source .env/bin/activate
    pip install -r requirements-doc.txt

To build the documentation, make sure to have your virtual environment enabled.

.. code-block:: none

    source .env/bin/activate

Then go to `doc` and simply call

.. code-block:: none

    make html

Your new build documentation is in ``doc/_build/html`` and you can view it with your favourite browser.

.. note::
    We call ``sphinx-build`` with ``-W`` which turns warnings into errors.
