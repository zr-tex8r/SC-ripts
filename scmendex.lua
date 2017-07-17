-- scmendex.lua
prog_name = "scmendex"
version = "0.2"
mod_date = "2016/11/13"
verbose = false
----------------------------------------
use_stdin, in_files, out_file, sty_file, log_file = nil
unpack = unpack or table.unpack
----------------------------------------
do
  function read_index(file)
    log("Skipping input file %s....done (relax).", file)
  end
end
----------------------------------------
do
  local done = false
  local function make_index()
    return [=[
\clearpage
\begingroup
  \catcode`\@=11 \let\u@\dimen@ii
  \u@=0.428446\hsize \divide\u@\@cclvi
  \font\sc@main=ipxm-r-u26 at 240\u@
  \font\sc@sub=ipxg-r-u30 at 80\u@
  \hb@xt@\hsize{\sc@sub\hfil\hfil
    \raise20\u@\hbox{\char"55}\hfil
    \raise32\u@\hbox{\char"4F}\hfil
    \raise32\u@\hbox{\char"44}\hfil
    \raise20\u@\hbox{\char"93}\hfil\hfil}%
  \vskip20\u@
  \hb@xt@\hsize{\sc@main\hfil\char"03\hfil}%
  \par
\endgroup
\clearpage
]=]
  end
  function write_index()
    local out = io.open(out_file, "wb")
    sure(out, "Coundn't open file %s.", out_file)
    log("Make index file....done.")
    out:write(make_index())
    out:close()
    done = true
  end
  function out_stat()
    if done then
      log("Output written in %s.", out_file)
    else
      log("Nothing written in output file.")
    end
  end
end
----------------------------------------
do
  local logf = nil
  local nwarn, nerr = 0, 0
  function log_open(file)
    if not file then return end
    logf = io.open(file, "wb")
    sure(logf, "Couldn't open file %s.", file)
  end
  local function info(v, ...)
    local msg = string.format(...).."\n"
    if v then io.stderr:write(msg) end
    if logf then logf:write(msg) end
  end
  function log(...)
    info(verbose, ...)
  end
  function log_close()
    if logf then logf:close() end
  end
  function logwarn(fmt, ...)
    info(true, "Warning: "..fmt, ...)
    nwarn = nwarn + 1
  end
  function logerror(fmt, ...)
    info(true, "Warning: "..fmt, ...)
    nerr = nerr + 1
  end
  function log_stat()
    if not log_file then return end
    local n, t = nerr, "errors"
    if nerr == 0 then n, t = nwarn, "warnings" end
    log("%d %s, written in %s.", n, t, log_file)
  end
  function abort(fmt, ...)
    info(true, "Fatal: "..fmt, ...)
    nerr = nerr + 1
    error("ABORT")
  end
  function sure(test, ...)
    if test then return end
    abort(...)
  end
end
----------------------------------------
do
  local function show_usage()
    io.stderr:write(([[
%s - Snowman index processor, version %s [%s].
usage:
%% %s[.lua] [-ilqrcgfEJSTU] [-s sty] [-d dic] [-o ind] [-t log] [-p no] [-I enc] [--] [idx0 idx1 ...]
options:
-i      use stdin as the input file.
-l      use letter ordering.
-q      quiet mode.
-r      disable implicit page formation.
-c      compress blanks. (ignore leading and trailing blanks.)
-g      make Japanese index head <`8'>.
-f      force to output kanji.
-s sty  take sty as style file.
-d dic  take dic as dictionary file.
-o ind  take ind as the output index file.
-t log  take log as the error log file.
-p no   set the starting page number of index.
-E      EUC mode.
-J      JIS mode.
-S      ShiftJIS mode.
-T      ShiftJIS terminal.
-U      UTF-8 mode.
-I enc  internal encoding for keywords (enc: euc or utf8).
idx...  input files.
]]):format(prog_name, version, mod_date, prog_name))
    os.exit(0)
  end
  local function show_banner()
    log([[This is %s version %s [%s].]],
        prog_name, version, mod_date)
  end
  local function with_ext(file, ext, forced)
    if not file then return file end
    local s = file:find("%.%w+$")
    if not s then return file.."."..ext
    elseif forced then return file:sub(1, s - 1).."."..ext
    else return file
    end
  end
  function resolve_file_names()
    if out_file then
      out_file = with_ext(out_file, "ind")
    else
      out_file = with_ext(in_files[1], "ind", true)
    end
    if log_file then
      log_file = with_ext(log_file, "ilg")
    else
      log_file = with_ext(in_files[1], "ilg", true)
    end
    for i = 1, #in_files do
      in_files[i] = with_ext(in_files[i], "idx")
    end
  end
  function read_option()
    if #arg == 0 then show_usage() end
    local idx = 1
    verbose = true; use_stdin = false
    while idx <= #arg do
      local opt = arg[idx]
      if opt:sub(1, 1) ~= "-" then break end
      if opt == "-i" then
        use_stdin = true
      elseif opt == "-q" then
        verbose = false
      elseif opt == "-o" then
        idx = idx + 1; out_file = arg[idx] or ""
      elseif opt == "-t" then
        idx = idx + 1; log_file = arg[idx] or ""
      elseif opt:find("^-[lrcgfEJSTU]$") then
        -- no-op
      elseif opt:find("^-[sdotpI]$") then
        idx = idx + 1
      else show_usage()
      end
      idx = idx + 1
    end
    if #arg == 0 then use_stdin = true end
    in_files = { unpack(arg, idx) }
  end
  function main()
    read_option()
    local ok, emsg = pcall(function()
      resolve_file_names()
      sure(not use_stdin, "Use of stdin is not yet supported.")
      log_open(log_file)
      show_banner()
      for i = 1, #in_files do
        read_index(in_files[i])
      end
      write_index()
      log_stat()
      out_stat()
      log_close()
    end)
    if not ok then
      if not emsg:find("ABORT$") then
        abort("Something went wrong.")
      end
      log_stat()
      out_stat()
      log_close()
    end
  end
end
----------------------------------------
main()
-- EOF
