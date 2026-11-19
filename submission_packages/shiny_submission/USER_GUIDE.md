# MusicPulse — Short User Guide

## Getting Started

Use **R 4.6.2** for the tested environment (the startup check permits R 4.3+, but other versions were not independently accepted). RStudio is optional. Extract the entire folder, including data/ and www/.

Open a terminal inside MusicPulse-Final:

```text
Rscript requirements.R
Rscript run_app.R
```

Or set RStudio's working directory to this folder and run `source("requirements.R")`, then `source("run_app.R")`. Open **http://127.0.0.1:8765** if needed. Initial loading takes several seconds. Internet is needed for installing packages and opening KuGou pages; local data and audio work offline afterward. Stop with Ctrl+C in the terminal or Esc in RStudio.

## Dashboard Navigation

- **Overview:** Explore archived coverage, candidate performance, song details and available local previews.
- **Music Features:** Compare Genre, Mood and duration of native units. Keywords are researcher-defined associations, not lyric frequencies.
- **Dynamics:** Compare first observations, observed-day counts and monthly visibility of shared candidates.
- **China vs US:** Compare the two supplied historical samples using independent country, Genre, first-observed and relative-month filters.

## A. Explore a Song

1. In Overview, change the **Global date filter** or click **Full window**. KPIs and the Venn stay fixed for the full dataset; bubbles, list and details follow the dates.
2. Search by title/Candidate ID and change sorting. Click a row to update details and bubble highlighting. Clicking a bubble also selects and locates the corresponding row.
3. Click **Preview Audio** where available. Press Play in the centered modal, pause or drag the progress bar. The default first 30 clips are the supplied videos' first **up to 20 seconds**, not certified choruses or independently verified Douyin recordings.
4. Close with **X**, **Close** or **Esc** to stop playback. Switching songs clears the previous player. Other candidates may correctly show **Preview unavailable**.

## B. Compare Music Characteristics

1. Open Music Features; select multiple Genre and Mood labels. Try **Select all** and **Clear**.
2. Bars/heatmap highlight selected labels while keeping all categories and percentages visible. The keyword cloud updates with your selections.
3. Dates select each native unit's latest actual metadata within the window. Douyin duration remains in unverified source units; KuGou milliseconds are converted to minutes.

## C. Explore Song Dynamics

1. Select **Category**, **Label** where applicable, and **Sort By**. Timeline and monthly matrix use the same Top 10 order. Scroll the matrix horizontally for later months; unmatched row slots remain grey.
2. Click a song/segment/cell for Selected Song Dynamics; use the return control for the Top 10 summary. The separate Mood/Genre lead–lag switch uses all eligible shared candidates, not only the Top 10.
3. Click the independent **Open on KuGou** icon to open the verified official page in a **new tab**. Clicking the song name still selects it. External autoplay is not promised.

## D. Compare the Supplied Markets

1. Choose **Compare Both**, **China** or **United States** in China vs US.
2. Select Genre labels, a first-observed direction and **Relative Month Range**. All four charts and page KPIs update together.
3. Read each country's actual date interval beside the slider. It selects the month when both platforms have been observed, retaining full-history first dates. This page is independent of the China-only global dates.
4. Positive timing difference means short-video earlier. The diverging chart retains its directional axis; end labels show directional magnitude and hover retains signed Net Priority.

## Interpretation and Use

The **95 shared songs are title-matched candidates**, not verified identical recordings. Platform recorded positions are not equivalent official ranks. First observation is not release, first popularity or causal origin; missing observations are not zero popularity. China covers **14 Nov 2024–13 Nov 2026** (last day may be partial), versus **1 Jun 2020–31 May 2022** for the reference. Spotify is GLOBAL and TikTok geography is unverified, limiting US-market interpretations. Multi-label percentages may overlap.

Audio is authorized by the provider's statement for **teacher/team private local course review only**. Do not publish or deploy the audio publicly. See COURSE_DISTRIBUTION_PERMISSION.md and THIRD_PARTY_NOTICES.md.