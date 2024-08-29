#show: wm-manuscript.with(
$if(title)$
  title: [$title$],
$endif$
$if(running-head)$
  running-head: [$running-head$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.id$$sep$, $endfor$],
      $if(it.orcid)$orcid: "https://orcid.org/$it.orcid$",$endif$
      $if(it.email)$email: [$it.email$]$endif$),
$endif$
$endfor$
    ),
$endif$
$if(affiliations)$
  affiliations: (
    $for(affiliations)$(
      id: "$it.id$",
      name: "$it.name$",
      $if(it.department)$department: "$it.department$"$endif$
    ),
    $endfor$
  ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(wordcount)$
  wordcount: [$wordcount$],
$endif$
)