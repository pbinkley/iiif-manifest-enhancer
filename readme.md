# IIIF Manifest Enhancer

In order to make Stanford presidents' reports and other publications more usable, I want to enhance their manifests with tables of contents. 

- Start with a bare-bones manifest that just includes the sequence of pages, labelled from 1 up
- Split into multiple manifests if needed (e.g. for cases where several items were bound together and then scanned as a single sequence)
- Generate a TOC via OCR, with titles and page numbers in yaml, allowing nesting
- e.g.

```
Book
  - Chapter 1: 1
    - Section 1.1: 1
    - Section 1.2: 13
```

- Have a script that will read in the manifest and the TOC, taking as a parameter the offset of page one (e.g. for an item with pp.i-viii before page 1, pass in 9 as offset of page 1)
  - the script generates new labels for all pages representing their proper page number
  - the script also generates a TOC sequence and inserts it, so that a proper table of contents will appear in the IIIF client
- out of scope for now:
  - anomalies in the page numbering sequence (e.g. unnumbered pages such as plates) - we'll stick to a simple model allowing sequence of roman-numeral-numbered pages followed by a sequence of arabic-numeral-numbered page, both starting at one


I think I can just use a single range structure (i.e., I won't attempt to enumerate all the canvases in a chapter)

```
"structures": [
  {
    "@id": "http://example.org/iiif/book1/range/r0",
    "@type": "sc:Range",
    "label": "Table of Contents",
    "viewingHint": "top",
    "members": [
      {
        "@id": "http://example.org/iiif/book1/canvas/cover",
        "@type": "sc:Canvas",
        "label": "Front Cover"
      },

      ... more canvases for the start pages of the chapters ...

    ]
  }
]
```

Note: I'll have to replace uris above the canvas level with my own, so as not to conflict with Stanford's or to appear to attribute things to Stanford that are actually my work. I'll have to add metadata to make the relationship clear.
