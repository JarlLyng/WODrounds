# Site copy

The words for the redesigned home page (#182), one file per language: `en`, `da`, `de`, `es`,
`fr`, `nb` and `sv`. Every file has the same keys, so the page is built the same way in all
seven. `nb` is published under `docs/no/`.

These files are the one place the home page's product facts live. Change a fact here, in all
seven files, and rebuild, rather than editing a page by hand.

## What each section holds

- `meta`: the page title and description.
- `hero`: the headline (the owner's choice, kept on purpose), the line under it, and the loop's
  alt text.
- `pieces`: the four frameless pieces, each with a short headline, one sentence and a link to
  its timer page (`links`).
- `tour`: the phone that stays, one step per screen.
- `where`: the big "5", the line under it, and the traits. Every trait has to be true on the
  platforms it names (#125). The iPhone Duo trait is added only once the Duo version is live.
- `assurances`: no account, paid for once, and the App Store's privacy label in Apple's own
  wording for each language, as read from the store page on 2026-10-12. Check it again in App
  Store Connect before the page ships, and whenever the label changes.
- `maker`: the maker's note, signed "Jarl".
- `faq`: mirrored in the FAQPage JSON-LD.

## The app's language on each page

`appLanguage` is the language the page's captures show. The app's interface is English, Danish
and Spanish, so the German, French, Norwegian and Swedish pages show the English app, and their
copy names the English buttons (Start, Stop, Done) and says so in the FAQ. Spoken cues are
English in every language until recorded per-language cues ship (`docs/VOICE_CUES.md`).

## Rules the copy keeps

`VOICE.md` in the hub: no em-dashes, no bullet lists in prose, pay-once framing and never
"free", no superlatives beyond the headline, no hand-written or converted prices (the store
fragment and the offer JSON carry the price). And none of the claims a platform can't back: no
sync to the Mac or Apple TV, no sound on the Mac or the Watch, no For Time on the Watch without
the iPhone.
