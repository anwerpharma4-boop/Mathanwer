# Manual device test checklist

Automated tests cover the logic and gestures (see `test/`), but the following must be checked on a real
Android phone **and** a tablet, because they depend on the device (PDF renderer, audio output, microphone,
storage, performance). Record the device model, Android version and result for each line.

## 0. Install and offline

- [ ] Install `app-release.apk` (allow "install unknown apps" for the file manager).
- [ ] Turn on **airplane mode** (Wi-Fi and mobile data off) before opening the app. Every check below is done offline.
- [ ] The app opens to the home screen in a few seconds; the robot mascot is shown.

## 1. Original textbook reader

- [ ] Home → *Original Textbook* opens on page 1 (cover) the first time.
- [ ] Slide/next through pages 1 → 96; every page appears, in the original order, and matches the printed book.
- [ ] Printed page number in the page corner equals "Page N / 96" in the top bar (spot-check 8, 44, 79, 94).
- [ ] Two-finger pinch zooms in smoothly to large magnification and back out; text and small labels
      (e.g. page 19 labels, page 80 transcripts) become sharp after the zoom settles.
- [ ] While zoomed, one finger moves the page left/right/up/down; it stops at the page edges; the zoom does
      not reset while moving; it does not jump to another page.
- [ ] Double-tap zooms in where tapped; double-tap again returns to the whole page.
- [ ] Buttons: zoom −, zoom +, *Fit width*, *Fit page*, *Reset zoom* behave as named (also in landscape).
- [ ] Not zoomed: swipe left = next page, swipe right = previous page.
- [ ] *Continuous* mode (icon in the top bar): scroll vertically through pages; pinch-zoom and pan work there too.
- [ ] Thumbnails (grid icon) show page images; tapping one opens it.
- [ ] Search: "zoo" lists pages 44+; "45" jumps to page 45; "zebra" finds pages 41 and 96.
- [ ] Bookmark a page; it appears under *Bookmarks*; leave the reader and come back → it reopens on the last page.
- [ ] Full screen hides the bars; the small button restores them.
- [ ] Rotate the device while zoomed and while not zoomed → no crash, page still visible.
- [ ] Rapidly zoom/pan/turn pages for 1 minute → no crash, no black pages, memory stays stable.

## 2. Audio (British English)

- [ ] Settings → test buttons: "Hello. I'm Robbie.", letter "Z" (must say **"zed"**), "tomato" (/təˈmɑːtəʊ/).
- [ ] Alphabet → several letters: letter **name** and letter **sound** both play and are clear.
- [ ] Vocabulary cards and lesson words play; Listening → a conversation plays line by line; *Play all* works;
      *Slow* is slower than *Normal*.
- [ ] Sound effects play for right/wrong answers and can be switched off in Settings.
- [ ] Settings → *Check device voice*: reports whether an offline en-GB device voice exists (either result is fine;
      the app's own audio does not depend on it).
- [ ] A native British English speaker listens to a sample of words, letters and sentences and notes anything unclear.

## 3. Learning features

- [ ] Start Learning opens Unit 1 Lesson 1; after finishing it, Start Learning goes to Lesson 2.
- [ ] Each lesson tab: *Book page* shows the right original page (Unit 1 Lesson 4 → page 11) and can be zoomed;
      *Open in textbook* opens the reader at that page.
- [ ] Alphabet: tracing with a finger shows ink; tracing the letter well earns a star; scribbling elsewhere does not.
- [ ] Each of the 12 games can be played to the end; wrong answers never stop the child; stars appear at the end.
- [ ] Listen and repeat → *Record*: first time asks for microphone permission; recording plays back as "My voice".
      Denying permission shows a friendly message and the activity still works.
- [ ] Drawing: draw, change colours and brush size, eraser, undo, clear, save → saved picture appears in *My drawings*.
- [ ] Quizzes: unit quiz, big challenge, *Practise these again* (after some wrong answers).

## 4. Progress and parents

- [ ] Earn stars/badges, close the app completely (swipe away), reopen → stars, badges, lessons, bookmarks are kept.
- [ ] Settings → Parent dashboard → wrong answer is refused, right answer opens it; data matches what was done
      (lessons, time, quiz scores, words needing practice).
- [ ] *Reset all progress* clears everything after confirmation.

## 5. Interface

- [ ] Settings → العربية: menus and parent screens switch to Arabic, right-to-left; English words, sentences
      and the textbook stay English and left-to-right. Switch back to English.
- [ ] Portrait and landscape on phone and tablet: nothing is cut off; buttons are large enough for a child.
- [ ] Android "Remove animations" accessibility setting: the mascot stops moving; everything still works.
