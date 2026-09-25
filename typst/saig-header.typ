#let saig-current-section = context {
  let prior = query(selector(heading.where(level: 1)).before(here()))
  let upcoming = query(selector(heading.where(level: 1)).after(here()))
  let selected = none

  if upcoming.len() > 0 and upcoming.first().location().page() == here().page() {
    selected = upcoming.first()
  } else if prior.len() > 0 {
    selected = prior.last()
  }

  if selected == none {
    [TECHNICAL REPORT]
  } else {
    selected.body
  }
}

#let saig-header = context [
  #set text(font: "DM Mono", size: 7.2pt, fill: rgb("#4F747D"))
  #grid(
    columns: (1fr, 1.4fr, 1fr),
    align(left)[
      #link("https://sustainableaigroup.com/")[Sustainable AI Group]
    ],
    align(center)[#saig-current-section],
    align(right)[Page #counter(page).display("1")]
  )
  #v(5pt)
  #line(length: 100%, stroke: 0.55pt + rgb("#E6ECED"))
]

#let saig-footer = none

#set page(
  header: saig-header,
  footer: saig-footer,
  numbering: none,
)

#set par(justify: false, leading: 0.72em)

// Refined long-document typography.
#show figure.caption: set text(font: "DM Sans", size: 9pt, fill: rgb("#5D7076"))
#show table: set table(
  inset: (x: 7pt, y: 6pt),
  stroke: (x, y) => (
    bottom: 0.5pt + rgb("#D5DFE1")
  ),
  fill: (x, y) => {
    if y == 0 {
      rgb("#F5F1E9")
    } else if calc.even(y) {
      rgb("#F7F9F9")
    } else {
      white
    }
  }
)

#show table: it => block(
  above: 9pt,
  below: 12pt,
  radius: 4pt,
  clip: true,
)[
  #set text(font: "DM Sans", size: 8.8pt)
  #it
]
