// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

// Based on quarto-ext/typst-templates/main/ams

#let wm-manuscript(
  // The article's title.
  title: "Paper title",

  // An array of authors. For each author you can specify a name and email. 
  //Everything but  but the name is optional.
  authors: (),

  affiliations: (),

  // Your article's abstract. Can be omitted if you don't have one.
  abstract: none,

  // The article's paper size. Also affects the margins.
  paper-size: "a4",

  fontsize: 12pt,

  font: ("Times", "Times New Roman"),

  anonymous: false,

  title-page-only: false,

  wordcount: none,

  date: none,

  // The document's content.
  body,
) = {


  // CONSTANTS //
  let normal-size =  fontsize
  let footnote-size = 0.8*fontsize
  let large-size = 1.2*fontsize

  
  // FUNCTIONS //

  // Create a string of authors' names.
  let show_authors = {
    let names = ()
    let affs = ()

    for author in authors {
      let aff_id = author.affiliation.text.replace("aff-", "")
      let name = [#author.name#if(affiliations.len() > 1){super[#aff_id]}]
      names.push(name)
    }
    
    for affiliation in affiliations {
      let aff_id = affiliation.id.replace("aff-", "")
      let aff = [#if(affiliations.len() > 1){super[#aff_id]}#affiliation.name]
      affs.push(aff)
    }
    par(leading: normal-size)[#align(center)[#names.join(", ", last: " and ")]]
    par(leading: normal-size)[#align(center)[_#affs.join("\n")_]]
  }


  // Settings //

  // Set document metadata.
  set document(title: title)

  // Set page
  set page(paper: paper-size, numbering: "1")


  // Set the body font. 
  set text(size: normal-size, font: font)
  

  // Configure paragraph properties.
  set par(first-line-indent: 1.2em,
          justify: true, 
          leading: normal-size*1.5)
  show par: set block(spacing: normal-size*1.5)


  // Headings
  set heading(numbering: "1.")
  show heading: it => {
    // Create the heading numbering.
    let number = if it.numbering != none {
      counter(heading).display(it.numbering)
      h(7pt, weak: true)
    }

    set text(size: normal-size)

    // Level 1
    if it.level == 1 {
      set par(first-line-indent: 0em)
      v(large-size*2, weak: true)
      number
      it.body
      v(large-size*2, weak: true)

    } else {
      v(large-size*2, weak: true)
      if it.level > 2 {
        text(weight: "regular", style: "italic")[#number #it.body]
      } else {
        text[#number #it.body]
      }
      v(large-size, weak: true)
  
    }
  }

  // Configure links.
  show link: set text(fill: rgb("#20425e"))

  // Space around figures
  show figure: set block(inset: (top: 0.5em, bottom: 2em))

  // CONTENTS //

  // Display the title and authors.
  v(35pt, weak: true)
  align(center, {
    text(size: large-size, weight: 700, title)
    v(25pt, weak: true)
  })
  if anonymous == false {
    show_authors
  }
  
  if not title-page-only {
    // Display date and word count
    if date != none or wordcount != none {
    align(center)[
      #text(size: footnote-size)[
        \(#if date != none [#date, ]#if wordcount != none [#wordcount words]\)
      ]
    ]
    }
    // Display the abstract
    if abstract != none {
      v(20pt, weak: true)
      set text(normal-size)
      show: pad.with(x: 35pt)
      show par: set par(leading: 0.65em)
      abstract
    }

    // Display the article's contents.
    v(29pt, weak: true)
    body
  }

}


#show: wm-manuscript.with(
  title: [Title of the paper],
  authors: (
    ( name: [First Author],
      affiliation: [aff-1],
      
      ),
    ( name: [Second Author],
      affiliation: [aff-2],
      
      ),
    ),
  affiliations: (
    (
      id: "aff-1",
      name: "University of Somewhere",
      
    ),
    (
      id: "aff-2",
      name: "University of Elsewhere",
      
    ),
    
  ),
  date: [2024-08-29],
  abstract: [Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Praesent auctor, sapien eget malesuada efficitur, magna sem facilisis metus, at venenatis metus arcu a tortor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus euismod, sapien in vestibulum interdum, purus velit efficitur mauris, ac ornare urna eros eget nulla. Vivamus nec libero et erat sagittis congue. Duis auctor, sapien sed tincidunt efficitur, magna neque congue velit, vel congue augue lacus eget metus. Donec auctor, nibh eget posuere efficitur, magna est tincidunt nulla, at condimentum sapien est a sem.],
  wordcount: [659],
  font: "Crimson Pro",
  fontsize: 12pt,
  title-page-only: true,
)

= Intro
<intro>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Praesent auctor, sapien eget malesuada efficitur, magna sem facilisis metus, at venenatis metus arcu a tortor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus euismod, sapien in vestibulum interdum, purus velit efficitur mauris, ac ornare urna eros eget nulla. Vivamus nec libero et erat sagittis congue. Duis auctor, sapien sed tincidunt efficitur, magna neque congue velit, vel congue augue lacus eget metus. Donec auctor, nibh eget posuere efficitur, magna est tincidunt nulla, at condimentum sapien est a sem.

And here is an example of a #highlight[highlighthed text.]

= Theory
<theory>
Lorem ipsum dolor sit amet, consectetur adipiscing elit (#link(<ref-Jaspers-etal2024>)[Jaspers, Mazrekaj, & Machado, 2024];). Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Praesent auctor, sapien eget malesuada efficitur, magna sem facilisis metus, at venenatis metus arcu a tortor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus euismod, sapien in vestibulum interdum, purus velit efficitur mauris, ac ornare urna eros eget nulla. Vivamus nec libero et erat sagittis congue. Duis auctor, sapien sed tincidunt efficitur, magna neque congue velit, vel congue augue lacus eget metus . Donec auctor, nibh eget posuere efficitur, magna est tincidunt nulla, at condimentum sapien est a sem (#link(<ref-MachadoJaspers2023>)[Machado & Jaspers, 2023];).

= Data and metthod
<data-and-metthod>
== Sample
<sample>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Praesent auctor, sapien eget malesuada efficitur, magna sem facilisis metus, at venenatis metus arcu a tortor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus euismod, sapien in vestibulum interdum, purus velit efficitur mauris, ac ornare urna eros eget nulla. Vivamus nec libero et erat sagittis congue. Duis auctor, sapien sed tincidunt efficitur, magna neque congue velit, vel congue augue lacus eget metus. Donec auctor, nibh eget posuere efficitur, magna est tincidunt nulla, at condimentum sapien est a sem.

== Variables
<variables>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Praesent auctor, sapien eget malesuada efficitur, magna sem facilisis metus, at venenatis metus arcu a tortor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus euismod, sapien in vestibulum interdum, purus velit efficitur mauris, ac ornare urna eros eget nulla. Vivamus nec libero et erat sagittis congue. Duis auctor, sapien sed tincidunt efficitur, magna neque congue velit, vel congue augue lacus eget metus. Donec auctor, nibh eget posuere efficitur, magna est tincidunt nulla, at condimentum sapien est a sem.#footnote[This is a footnote.]

== Analytical strategy
<analytical-strategy>
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Praesent auctor, sapien eget malesuada efficitur, magna sem facilisis metus, at venenatis metus arcu a tortor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus euismod, sapien in vestibulum interdum, purus velit efficitur mauris, ac ornare urna eros eget nulla. Vivamus nec libero et erat sagittis congue. Duis auctor, sapien sed tincidunt efficitur, magna neque congue velit, vel congue augue lacus eget metus. Donec auctor, nibh eget posuere efficitur, magna est tincidunt nulla, at condimentum sapien est a sem.

Also see @tbl-test. There is also @tbl-app1 in the Appendix.

Some math here: $ lambda x : x^2 $

= Results
<results>
#figure([
#show figure: set block(breakable: true)

#let nhead = 2;
#let nrow = 9;
#let ncol = 8;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (6, 10), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7), (7, 8), (7, 9), (7, 10),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    column-gutter: 5pt,
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 2, start: 0, end: 8, stroke: 0.05em + black),
 table.hline(y: 11, start: 0, end: 8, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
table.cell(stroke: (bottom: .05em + black), colspan: 3, align: center)[Hamburgers],table.cell(stroke: (bottom: .05em + black), colspan: 2, align: center)[Halloumi],[ ],table.cell(stroke: (bottom: .05em + black), colspan: 1, align: center)[Tofu],[ ],
[mpg], [cyl], [disp], [hp], [drat], [wt], [qsec], [vs],
    ),

    // tinytable cell content after
[21.0], [6], [160.0], [110], [3.90], [2.620], [16.46], [0],
[21.0], [6], [160.0], [110], [3.90], [2.875], [17.02], [0],
[22.8], [4], [108.0], [93], [3.85], [2.320], [18.61], [1],
[21.4], [6], [258.0], [110], [3.08], [3.215], [19.44], [1],
[18.7], [8], [360.0], [175], [3.15], [3.440], [17.02], [0],
[18.1], [6], [225.0], [105], [2.76], [3.460], [20.22], [1],
[14.3], [8], [360.0], [245], [3.21], [3.570], [15.84], [0],
[24.4], [4], [146.7], [62], [3.69], [3.190], [20.00], [1],
[22.8], [4], [140.8], [95], [3.92], [3.150], [22.90], [1],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
This is an awesome table
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-test>


Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent at elit vel orci congue congue. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. We can see the same in @fig-scatter.

#figure([
#box(image("template_files/figure-typst/fig-scatter-1.svg"))
], caption: figure.caption(
position: bottom, 
[
This is an awesome figure
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-scatter>


= References
<references>
#block[
// More compact paragraphs for refs
#set par(justify: true, 
        hanging-indent: 1.5em,
        leading: 1em)
#block[
Jaspers, E., Mazrekaj, D., & Machado, W. (2024). Doing Genders: Partner’s Gender and Labor Market Behavior. #emph[American Sociological Review];, #emph[89];(3), 518–541. #link("https://doi.org/10.1177/00031224241252079")

] <ref-Jaspers-etal2024>
#block[
Machado, W., & Jaspers, E. (2023). Money, Birth, Gender: Explaining Unequal Earnings Trajectories following Parenthood. #emph[Sociological Science];, #emph[10];, 429–453. #link("https://doi.org/10.15195/v10.a14")

] <ref-MachadoJaspers2023>
] <refs>
#pagebreak()
#set heading(numbering: "A.1")
#set figure(numbering: num =>
  numbering("A1", counter(heading).get().first(), num)
)    
#counter(heading).update(0)
#counter(figure.where(kind: "quarto-float-tbl")).update(0)
#counter(figure.where(kind: "quarto-float-fig")).update(0)

// Reset formatting that was changes for refs
#set par(first-line-indent: 1.2em,
          justify: true, 
          leading: 1.5em)
#show par: set block(spacing: 1.5em)
= Appendix
<appendix>
== Appendix section
<appendix-section>
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 9;
#let ncol = 8;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7), (7, 8), (7, 9),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
 table.hline(y: 10, start: 0, end: 8, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[mpg], [cyl], [disp], [hp], [drat], [wt], [qsec], [vs],
    ),

    // tinytable cell content after
[21.0], [6], [160.0], [110], [3.90], [2.620], [16.46], [0],
[21.0], [6], [160.0], [110], [3.90], [2.875], [17.02], [0],
[22.8], [4], [108.0], [93], [3.85], [2.320], [18.61], [1],
[21.4], [6], [258.0], [110], [3.08], [3.215], [19.44], [1],
[18.7], [8], [360.0], [175], [3.15], [3.440], [17.02], [0],
[18.1], [6], [225.0], [105], [2.76], [3.460], [20.22], [1],
[14.3], [8], [360.0], [245], [3.21], [3.570], [15.84], [0],
[24.4], [4], [146.7], [62], [3.69], [3.190], [20.00], [1],
[22.8], [4], [140.8], [95], [3.92], [3.150], [22.90], [1],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
This is a table in the appendix
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-app1>


#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 9;
#let ncol = 8;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7), (7, 8), (7, 9),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
 table.hline(y: 10, start: 0, end: 8, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[mpg], [cyl], [disp], [hp], [drat], [wt], [qsec], [vs],
    ),

    // tinytable cell content after
[21.0], [6], [160.0], [110], [3.90], [2.620], [16.46], [0],
[21.0], [6], [160.0], [110], [3.90], [2.875], [17.02], [0],
[22.8], [4], [108.0], [93], [3.85], [2.320], [18.61], [1],
[21.4], [6], [258.0], [110], [3.08], [3.215], [19.44], [1],
[18.7], [8], [360.0], [175], [3.15], [3.440], [17.02], [0],
[18.1], [6], [225.0], [105], [2.76], [3.460], [20.22], [1],
[14.3], [8], [360.0], [245], [3.21], [3.570], [15.84], [0],
[24.4], [4], [146.7], [62], [3.69], [3.190], [20.00], [1],
[22.8], [4], [140.8], [95], [3.92], [3.150], [22.90], [1],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
A second table in the appendix
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-app2>





