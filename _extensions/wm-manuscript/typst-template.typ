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
          leading: normal-size*1.5,
          spacing: normal-size*1.5)


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
  // show figure: set block(inset: (top: 0.5em, bottom: 2em))

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

