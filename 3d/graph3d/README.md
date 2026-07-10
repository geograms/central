# graph3d

A native Flutter port of the TripleCheck 3D software view — the CSS3D graph in
`../old/graph-2017-01-09/`. Same graph, same query language, same review flow,
running on Linux, Android, macOS, Windows and iOS without a browser.

## Running it

    ./launch.sh              # build if stale, then run (debug)
    ./launch.sh release      # optimised
    ./launch.sh dev          # flutter run, with hot reload
    ./launch.sh data         # regenerate the dataset from ../old/graph-2017-01-09

Builds go through `~/bin/android-build-locked`, the machine-wide serialisation
lock, when it is present.

## The data

`tool/convert_data.js` runs the original's six loose `.js` files in a sandbox,
reads the globals back out, and writes one typed bundle to
`assets/data/triplecheck.json` (426 nodes, 315 links, 7 match groups). It fails
loudly on a dangling link or a node/detail length mismatch rather than let the
graph draw the wrong file's licence.

**Identity is the array position, not the `id` column.** The dataset's `id`
values are neither ordered nor unique — nineteen files share an id with another
— and the original indexes everything by one-based position. `GraphNode.id` is
that position; `GraphNode.sourceId` keeps the original value for reference and
is never looked up.

Point the app at another TripleCheck run by swapping the `GraphDataSource` in
`main.dart`; `FileGraphDataSource` reads the same bundle from disk.

## Controls

Drag to rotate, scroll or pinch to zoom, two fingers to pan. Click a card to
select it and fly to it; click it again, double-click the background, or press
Escape to let go. Hovering a card for half a second shows its details without
selecting it.

Links are hidden in table view, exactly as in the original — a flat grid of 426
cards crossed by 315 lines is a cat's cradle.

## Rendering

Flutter has no depth buffer for widgets, so `Css3dStack` sorts the cards by
camera-space depth and paints them back to front. Three constraints, all
measured on an Oukitel C61 (Android 15, arm64) with the full 426 cards:

1. **Key the Stack's direct children.** The depth sort permutes them every
   frame; unkeyed, Flutter rematches by index and rebuilds every subtree.
   Keying dropped build time from 107ms to 24ms.

2. **Per-card blurs are unaffordable.** Flutter disables the raster cache under
   a perspective transform, so `RepaintBoundary` does not cache them and every
   blur recomputes each frame — about 0.74ms per card. The cyan glow is
   therefore reserved for the selected and hovered cards; everything else that
   is merely linked or found gets a brighter border.

3. **`Transform.filterQuality` cannot be used.** It snapshots the child through
   `ImageFilter.matrix`, which cannot express a perspective matrix, so most
   cards silently fail to draw. It benchmarks twenty times faster because it is
   rendering nothing.

Measured on that phone in the heaviest view — grid layout, all 315 links
animating, dragging so the whole stack rebuilds every frame — build 13ms,
raster 26ms, about 38fps. To check it yourself:

    flutter build apk --release --dart-define=GRAPH3D_FRAME_STATS=true
    adb logcat | grep FRAMES

Note also that `Quaternion.rotated` in `vector_math` applies the *inverse*
rotation, while `asRotationMatrix`, `Matrix4.compose` and
`Quaternion.fromRotation` apply the forward one. Mixing the two makes an orbit
camera circle a point it is not looking at.

## Where it departs from the original

Three of these are bug fixes, and they change what you see:

- The details panel labelled the copyright `License:`. It now says `Copyright:`.
- A search matching on the licence field reported the *copyright* as the matched
  text. It now reports the licence.
- The Matches Bin table's `Similarity` and `Hash` headers were swapped.

And three are deliberate:

- The always-on card glow is now a selection highlight, for the reason above.
- The camera frames each layout to the viewport instead of sitting at a fixed
  8000 units, so the table is legible. It never backs off *past* 8000, because
  fitting a 4200-unit-wide table into a portrait phone would reduce every card
  to a speck; there the graph overflows and you pan, tethered to the layout so
  it can never be lost off screen.
- Review verdicts persist to disk, per project, under the application support
  directory (`~/.local/share/com.geogram.graph3d/reviews/` on Linux).
