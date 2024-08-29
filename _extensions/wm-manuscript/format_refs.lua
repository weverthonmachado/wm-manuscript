-- Define the Typst code to be inserted before and after the refs
local typst_code = [[
// More compact paragraphs for refs
#set par(justify: true, 
        hanging-indent: 1.5em,
        leading: 1em)
]]


-- Function to insert Typst code before and after refs div
function Div(el)
    if el.identifier == "refs" then
        local new_content = {}
        table.insert(new_content, pandoc.RawBlock('typst', typst_code))
        for _, item in ipairs(el.content) do
            table.insert(new_content, item)
        end
        el.content = new_content
    end
    return el
end