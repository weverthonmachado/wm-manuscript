-- Define the Typst code to be inserted before the appendix
local typst_code = [[
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
          leading: 1.5em,
          spacing: 1.5em)
]]

-- Function to process header elements
function Header(el)
  -- Check if the header has the class "appendix"
  if el.classes:includes("appendix") then
    -- If it does, return a table with two elements:
    return {
      -- 1. A RawBlock containing the Typst code
      pandoc.RawBlock("typst", typst_code),
      -- 2. The original header element
      el
    }
  end
  -- If it's not an appendix header, return the element unchanged
  return el
end