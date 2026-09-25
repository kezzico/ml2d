function table_count(o)
  local n = 0
  for k,v in pairs(o) do
    n = n + 1
  end

  return n
end