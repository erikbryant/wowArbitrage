Utility = CreateFrame("Frame")

function Utility:ObjectToString(obj)
    if type(obj) == 'table' then
        local str = '{ '
        for key, val in pairs(obj) do
            if type(key) == 'table' then
                key = '<table:'..Internal:Dump(key)..'>'
            elseif type(key) ~= 'number' then
                key = '"'.. key ..'"'
            end
            str = str .. '['.. key ..'] = ' .. ObjectToString(val) .. ','
        end
        return str .. '} '
    else
        return tostring(obj)
    end
end
