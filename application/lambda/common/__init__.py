"""The layers every Lambda shares, after Martin Fowler's Patterns of Enterprise
Application Architecture (https://martinfowler.com/eaaCatalog/).

Dependencies run one way only. ``domain`` holds pure, I/O-free value objects
and imports nothing from the other layers. The build script bundles this
package into every Lambda's zip, so each Lambda folder holds only its handler.
"""
