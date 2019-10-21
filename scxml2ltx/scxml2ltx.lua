-- scxml2ltx.lua
prog_name = "scxml2ltx"
version = "0.2"
mod_date = "2017/08/01"
---------------------------------------- global parameters
verbose = 0
in_file, out_file, check, scsnowman = nil
---------------------------------------- helpers
unpack = unpack or table.unpack
do
  function str(val)
    return (type(val) == "table") and "{"..concat(val, ",").."}"
        or tostring(val)
  end
  function concat(tbl, ...)
    local t = {}
    for i = 1, #tbl do t[i] = str(tbl[i]) end
    return table.concat(t, ...)
  end
end
---------------------------------------- scxml2ltx
do
  local SBLK, NBLK = 1024, 1024
  local function read_top(file)
    local blks, t = {}, nil
    repeat
      t = file:read(SBLK)
      table.insert(blks, t)
    until #blks == NBLK or not t
    return table.concat(blks)
  end
  local function one_file(file)
    local v, t = 0, md5.sumhexa(read_top(file))
    info("MD5 value", t)
    for p = 1, 29, 4 do
      v = v + tonumber(t:sub(p, p + 3), 16)
    end
    return v % 65536
  end
  function hash_value()
    local v = 0
    if check then
      if #in_file == 0 then
        info("input from stdin")
        v = one_file(io.stdin)
      else
        for _, fn in ipairs(in_file) do
          info("input file", fn)
          local f = sure(io.open(fn, "rb"),
              "cannot open for input", fn)
          v = v + one_file(f); f:close()
        end
      end
    else
      info("no-check mode, input file is ignored")
    end
    return v % 65536
  end
end
---------------------------------------- scxml2ltx
do
  local color = {
    "red", "green!50!black", "blue", "black!50"
  }
  function latex_source(hv)
    if scsnowman then
      local col = color[hv % 4 + 1]
      info("muffler color", col)
      local par = (scsnowman == true) and
          ("hat,arms,buttons,snow,muffler="..col) or
          scsnowman
      return ([=[
\documentclass[a4paper]{article}
\usepackage{scsnowman,graphicx}
\pagestyle{empty}
\begin{document}\centering
\scalebox{36}{\scsnowman[%%
%s%%
]}
\end{document}
]=]):format(par)
    else
      return [=[
\documentclass[a4paper]{article}
\usepackage{type1cm}
\DeclareFontFamily{U}{ipxm}{}
\DeclareFontShape{U}{ipxm}{m}{n}{<->ipxm-r-u26}{}
\pagestyle{empty}
\begin{document}\centering
\fontsize{279}{0}\usefont{U}{ipxm}{m}{n}\symbol{3}
\end{document}
]=]
    end
  end
end
---------------------------------------- logging
do
  function log(level, ...)
    if verbose < level then return end
    io.stderr:write(concat({prog_name, ...}, ": ").."\n")
  end
  function info(...) log(1, ...) end
  function warn(...) log(-1, "warning", ...) end
  function abort(...) log(-2, ...); os.exit(1) end
  function sure(val, a1, ...)
    if val then return val end
    abort((type(a1) == "number") and ("ERROR("..a1..")") or a1, ...)
  end
end
---------------------------------------- main
do
  local function show_usage()
    io.stdout:write(([[
This is %s v%s <%s> by 'ZR'
Usage: %s [-i <in_file>] [-o <out_file>] [-C] [-S|-s <params>]
  -i <in_file>      input file name (default is stdin)
  -o <out_file>     output file name (default is stdout)
  -C                skip check for existence of files
  -S                not use scsnowman
  -s <params>       use scsnowman (with given params)
  -v                verbose
]]):format(prog_name, version, mod_date, prog_name))
    os.exit(0)
  end
  function read_option()
    in_file = {}; check = true; scsnowman = true
    local idx = 1
    while idx <= #arg do
      if arg[idx]:sub(1, 1) ~= "-" then break end
      local opt, oa = arg[idx]; idx = idx + 1
      if opt == "-h" or opt == "--help" then
        show_usage()
      elseif opt:match("^%-v+$") then
        verbose = #opt - 1
      elseif opt:match("^%-i") then
        if #opt > 2 then oa = opt:sub(3)
        else oa = arg[idx]; idx = idx + 1
        end
        sure(oa and oa ~= "", "missing argument", opt)
        table.insert(in_file, oa)
      elseif opt:match("^%-o") then
        if #opt > 2 then oa = opt:sub(3)
        else oa = arg[idx]; idx = idx + 1
        end
        sure(oa and oa ~= "", "missing argument", opt)
        out_file = oa
      elseif opt == "-C" then
        check = false
      elseif opt:match("^%-s") then
        if #opt > 2 then oa = opt:sub(3)
        else oa = arg[idx]; idx = idx + 1
        end
        sure(oa and oa ~= "", "missing argument", opt)
        scsnowman = oa
      elseif opt == "-S" then
        scsnowman = false
      else abort("unknown option", opt)
      end
    end
  end
  function output_file(str)
    local out = io.stdout
    if out_file then out = io.open(out_file, "wb") end
    sure(out, "cannot open for output", output_file)
    out:write(str)
    out:close()
  end
  function main()
    read_option()
    local hv = hash_value()
    info("hash value is", ("%04X"):format(hv))
    output_file(latex_source(hv))
  end
end
---------------------------------------- done
main()
-- EOF
