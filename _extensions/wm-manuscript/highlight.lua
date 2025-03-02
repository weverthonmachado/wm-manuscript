function RawInline(elem)
  -- Check if the element is HTML format and matches our special comment pattern
  if elem.format == "html" and elem.text:match("^<!%-%-!%s*(.-)%s*%-%->$") then
    -- Extract the text between the comment delimiters
    local highlighted_text = elem.text:match("^<!%-%-!%s*(.-)%s*%-%->$")
    -- Return a new RawInline element with 'typst' format, wrapping the extracted text in #highlight()
    return pandoc.RawInline('typst', '#highlight[' .. highlighted_text .. ']')
  end
end