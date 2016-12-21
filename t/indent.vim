describe 'indentation on new line'
  it 'starts on column 1 on first line'
    Expect getline(1) == ''
  end

  it 'stays on column 1 after hitting return on first line'
    normal <CR>
    Expect getline(2) == ''
  end
end
