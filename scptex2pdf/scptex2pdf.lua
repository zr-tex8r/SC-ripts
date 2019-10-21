-- scptex2pdf.lua
prog_name = "scptex2pdf"
version = "0.2"
mod_date = "2017/07/19"
---------------------------------------- global parameters
driver = "dvipdfmx"
prologue, src_file = nil
output_dir, tex_opts, driver_opts = nil
eptex, uptex, latex, stop, interm = nil
---------------------------------------- snowman
whatever = [[
       ____
    ___HHHH   _____   `1
   / .   . \ |NICE!|  `2
   \  ---  / |~~~~~
 V :#######: Y        `3
  \/   o*"*\/         `4
  {    o    }
   \_______/                                         HURRAY!!
]]
---------------------------------------- helpers
remove = table.remove
unpack = unpack or table.unpack
do
  function str(val)
    return (type(val) == "table") and "{"..concat(val, ",").."}"
        or tostring(val)
  end
  function insert(tbl, ...)
    for _, v in ipairs({...}) do table.insert(tbl, v) end
  end
  function concat(tbl, ...)
    local t = {}
    for i = 1, #tbl do t[i] = str(tbl[i]) end
    return table.concat(t, ...)
  end
end
---------------------------------------- run TeX
do
  local function quot(n)
    return '"'..n..'"'
  end
  local function slashify(str)
  return str:gsub("[\x81-\x9f\xe0-\xfc]?.", { ["\\"] = "/" })
  end
  local function make_essential(dvi)
    local cipher, alpha, t = "ZINTYWLVHK", "ABCDEF", {};
    for i = 0, 9 do t[cipher:sub(i+1, i+1)] = tostring(i) end
    local function hex(v) return string.char(tonumber(v, 16)) end
    local h = io.open(dvi, "wb")
    h:write((essential:gsub("%s", ""):gsub("["..cipher.."]", t)
        :gsub("[^0-9A-F]", "00"):gsub("..", hex)))
    h:close()
  end
  function run_tex()
    -- engine name
    local engine = (latex) and "platex" or (eptex) and "eptex" or "ptex"
    if uptex then engine = engine:gsub("p", "up") end
    kpse.set_program_name(engine)
    -- job name
    local src = slashify(src_file)
    if kpse.find_file(src) then -- nop
    elseif kpse.find_file(src..".tex") then src = src..".tex"
    elseif kpse.find_file(src..".ltx") then src = src..".ltx"
    else abort(1, "File cannot be found with kpathsea",
             src.."[.tex, .ltx]")
    end
    local job = src:gsub("%.[^.]+$", ""):gsub("^.*/", "")
    local dvi, pdf = job..".dvi", job..".pdf"
    -- make commands
    local tex_cmd, driver_cmd = {engine}, {"dvipdfmx"}
    if output_dir ~= "." then
      insert(tex_cmd, "-output-directory", quot(output_dir))
      dvi, pdf = output_dir.."/"..dvi, output_dir.."/"..pdf
      insert(driver_cmd, "-o", quot(pdf))
    end
    insert(tex_cmd, tex_opts)
    for _, v in ipairs(prologue) do insert(tex_cmd, quot(v)) end
    insert(tex_cmd, quot(src))
    insert(driver_cmd, driver_opts, quot(dvi))
    -- dispatch
    local ok = (function()
      if os.execute(concat(tex_cmd, " ")) ~= 0 then return end
      make_essential(dvi)
      if stop then return true end
      if os.execute(concat(driver_cmd, " ")) ~= 0 then return end
      info(pdf.." generated by "..driver..".")
      if interm then return true end
      os.remove(dvi)
      return true
    end)()
    if not ok then
      abort(2, "ptex2pdf processing of "..src.." failed.")
    end
  end
end
---------------------------------------- logging
do
  function info(...)
    io.stderr:write(concat({...}, ": ").."\n")
  end
  function abort(stat, ...)
    info(...); os.exit(stat)
  end
end
---------------------------------------- main
do
  local function show_whatever(...)
    local lines = {...}
    io.stdout:write((whatever:gsub("`(%d)", function(n)
      return lines[tonumber(n)] or ""
    end)))
  end
  local function show_usage(stat)
    io.stdout:write(([[
[texlua] %s[.lua] { option | basename[.tex] } ... 
options: -v  version
         -h  help
         -help print full help (installation, TeXworks setup)
         -e  use eptex class of programs
         -u  use uptex class of programs
         -l  use latex based formats
         -s  stop at dvi
         -i  retain intermediate files
         -ot '<opts>' extra options for TeX
         -od '<opts>' extra options for dvipdfmx
         -output-directory '<dir>' directory for created files
]]):format(prog_name))
    if stat then os.exit(stat) end
  end
  local function show_version(stat)
    io.stdout:write(([[
This is %s[.lua] version %s.
]]):format(prog_name, version))
    if stat then os.exit(stat) end
  end
  local function show_help(stat)
    show_usage()
    show_whatever("You don't see what it is?", "",
      "It's really something very fancy!", "")
    if stat then os.exit(stat) end
  end
  local function show_readme(stat)
    local rp, rc = ("%"):rep(61), (":"):rep(61)
    local rx, cr = " ! ! ! ! ! ! ! ! ! ! ! ", "\n"
    io.stdout:write(rp..cr..rx.." R E A D   M E "..rx..cr..rc..cr)
    show_whatever("How come you keep writing in the",
        "Japanese language or such things?",
        "You should rather make snowman,",
        "because it's far fancier!!")
    io.stdout:write(rc..cr..rp..cr)
    if stat then os.exit(stat) end
  end
  function read_option()
    if #arg == 0 then show_usage(0) end
    output_dir = "."; tex_opts = ""; driver_opts = "";
    eptex = false; uptex = false; latex = false;
    stop = false; interm = false; prologue = {}
    local idx = 1
    while idx <= #arg do
      local aa = arg[idx]; idx = idx + 1
      if aa:sub(1, 1) == "-" then
        if aa:sub(1, 2) == "--" then aa = aa:sub(2) end
        if aa == "-v" then
          show_version(0)
        elseif aa == "-readme" then
          show_readme(0)
        elseif aa == "-output-directory" then
          output_dir = arg[idx]; idx = idx + 1
        elseif aa:match("^%-output%-directory=") then
          output_dir = aa:match("=(.*)")
        elseif aa == "-print-version" then
          print(version); os.exit(0)
        elseif aa == "-h" then
          show_usage(0)
        elseif aa == "-help" then
          show_help(0)
        elseif aa == "-e" then
          eptex = true
        elseif aa == "-u" then
          uptex = true
        elseif aa == "-l" then
          latex = true
        elseif aa == "-s" then
          stop = true
        elseif aa == "-i" then
          interm = true
        elseif aa == "-ot" then
          tex_opts = arg[idx]; idx = idx + 1
        elseif aa:match("^%-ot=") then
          tex_opts = aa:match("=(.*)")
        elseif aa == "-od" then
          driver_opts = arg[idx]; idx = idx + 1
        elseif aa:match("^%-od=") then
          driver_opts = aa:match("=(.*)")
        else
          abort(1, "unknown option", aa)
        end
      else -- non-option
        insert(prologue, aa)
      end
    end
    if #prologue == 0 then
      abort(1, "No filename argument given, exiting.")
    elseif #prologue > 1 then
      info("Multiple filename arguments? OK, I'll take the latter one.")
    end
    src_file = remove(prologue)
  end
  function main()
    read_option()
    run_tex()
  end
end
---------------------------------------- done
essential = [[
FVZNZIHTKNCZICTBXUUOZTEHIBNZWYLWWHNZLFVWVYVZVWVYNZTNTZTZTH NETZT
HNETZTHT ATZTHTZTHHBOUUZIXOX        UUXOXX///Merry/Snowman///OXX
UXXOOFFFFFFFFAZ ULEWVYEHD              KIZNIBLTFTNZOOUO XTCXOXZA
XUOZHVWVZLALKVTLVNDLHCBHI              TZHLHEHDKIL TYBAYKFFLOXHI
TZYDHEH DKNXCYVBEYKFF ZUOHI          TZLZH EHDKNZINWACNWKFFLUXHI
TZHBHEHDKNZI HLDCLWHIT Z                V EHEAZXFBTTTWKILAV BEYF
TIFUU XOUFZOOXZAXUUZHVW                  VZLALKVTVNNDLHCAHINLZTH
CFHXXUNAZIHTKNC ZICTBUO                  XUZTEHZIH LWVYEZNZDTCEL
OZTOZIFTNZOXXUUTCUUUZAXX                UZHVWVZLALKVTLVNDLHF TIF
UXXOOFZOXXZAUUUZHVWVZLALKVT          VNNDLHFKUXUDVZNDFDFDFDFDFDF
]]
main()
-- EOF