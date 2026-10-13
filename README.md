# folio

Portfolio site of Prasenjit Vijay Hiwale, served by GitHub Pages at
https://prasenjithiwale.github.io/folio/.

Plain HTML and CSS, no build step. Each project lives in its own folder:

```
index.html            home page: projects listed as records in a log
assets/               shared styles, script and self-hosted JetBrains Mono (SIL OFL)
kaffy/
  index.html          project page
  install.sh          curl -fsSL https://prasenjithiwale.github.io/folio/kaffy/install.sh | sh
  releases/           published by kaffy's release workflow; do not edit by hand
    latest.txt        version the install script installs by default
    latest.json       version, date, size and checksum shown on the pages
    vX.Y.Z/           kaffy-vX.Y.Z-x86_64-unknown-linux-gnu.tar.gz and .sha256
```

The terminal screens on the kaffy page are real renders of the app, produced with
`cargo run -p kaffy-ui --example snapshot` in the kaffy repository.

To preview locally, serve the parent directory so paths match Pages:

```sh
cd .. && python3 -m http.server 8000   # then open http://localhost:8000/folio/
```
