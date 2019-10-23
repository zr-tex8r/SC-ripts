-- scmakesvf.lua
prog_name = "scmakesvf"
version = "0.2.1"
mod_date = "2019/10/22"
---------------------------------------- global parameters
baseshift, kanatfm, ucs, jistfm, ucsqtfm, chotai, useset3 = nil
atfmname, vfname, vtfmname = nil
snowman = nil
---------------------------------------- helpers
unpack = unpack or table.unpack
floor, ceil, abs = math.floor, math.ceil, math.abs
do
  TU = floor(2^20) -- TFM units per a point
  local function bp(n) return floor(2^n) end
  function int(v)
    return (v < 0) and ceil(v) or floor(v)
  end
  function str(v)
    return (type(v) == "table") and "{"..concat(v, ",").."}"
        or tostring(v)
  end
  function concat(tbl, ...)
    local t = {}
    for i = 1, #tbl do t[i] = str(tbl[i]) end
    return table.concat(t, ...)
  end
  --- bit_scan(integer, bit_len...)
  function bit_scan(v, ...)
    sure(type(v) == "number", 1)
    local k, r, v = {...}, {}, floor(math.max(0, v))
    for i = #k, 1, -1 do
      r[i] = v % bp(k[i]); v = floor(v / bp(k[i]))
    end
    return unpack(r)
  end
  --- glemish(number)
  -- A "fixed-random" function.
  function glemish(v)
    return floor(abs(math.sin(v)) * bp(48)) % bp(40)
  end
  --- temper(ctype)
  -- The height of snowman for a ctype in percentage.
  local temper_ = { 100, 25, 50, 0, 75 }
  function temper(c)
    return temper_[c] or (42 * c % 100)
  end
end
---------------------------------------- class 'reader'
do
  local reader_meta = {
    __tostring = function(self)
      return "reader("..self.name..")"
    end;
    __index = {
      cdata = function(self, ofs, len)
        return make_cdata(self:read(ofs, len))
      end;
      read = function(self, ofs, len)
        self.file:seek("set", ofs)
        local data = self.file:read(len)
        sure(data:len() == len, 1)
        return data
      end;
      close = function(self)
        self.file:close()
      end;
    }
  }
  function make_reader(fname)
    local file = io.open(fname, "rb")
    sure(file, "cannot open for input", fname)
    return setmetatable({
      name = fname, file = file
    }, reader_meta)
  end
end
---------------------------------------- class 'cdata'
do
  local cdata_meta = {
    __tostring = function(self)
      return "cdata(pos="..self._pos..")"
    end;
    __index = {
      pos = function(self, p)
        if not p then return self._pos end
        self._pos = p
        return self
      end;
      unum = function(self, b)
        local v, data = 0, self.data
        sure(#data >= self._pos + b, 11)
        for i = 1, b do
          self._pos = self._pos + 1
          v = v * 256 + data:byte(self._pos)
        end
        return v
      end;
      setunum = function(self, b, v)
        local t, data = {}, self.data
        t[1] = data:sub(1, self._pos)
        self._pos = self._pos + b
        t[b + 2] = data:sub(self._pos + 1)
        for i = 1, b do
          t[b + 2 - i] = string.char(v % 256)
          v = floor(v / 256)
        end
        self.data = table.concat(t, "")
        return self
      end;
      setsnum = function(self, b, v)
        local sv, av, bb = (v < 0), floor(abs(v)), floor(256^b)
        av = av % bb
        if sv then av = bb - av end
        self:setunum(b, av)
      end;
      str = function(self, b)
        local data = self.data
        self._pos = self._pos + b
        sure(#data >= self._pos, 13)
        return data:sub(self._pos - b + 1, self._pos)
      end;
      setstr = function(self, s)
        local t, data = {}, self.data
        t[1], t[2] = data:sub(1, self._pos), s
        self._pos = self._pos + #s
        t[3] = data:sub(self._pos + 1)
        self.data = table.concat(t, "")
        return self
      end;
      unums = function(self, b, num)
        local t = {}
        for i = 1, num do
          t[i] = self:unum(b)
        end
        return t
      end;
    }
  }
  function make_cdata(data)
    return setmetatable({
      data = data, _pos = 0
    }, cdata_meta)
  end
end
---------------------------------------- TFM something
do
  --- get_tfm(filename)
  -- Returns a object that contains the summary for the given TFH file.
  function get_tfm(file)
    local fp = io.open(file, "rb")
    if not fp then abort(0, 0, "%s is not found.", file) end
    local tfm = make_cdata(fp:read("*a"))
    fp:close()
    -- parse it
    sure(#tfm.data >= 28, 10)
    local tate, id = false, tfm:unum(2)
    if id == 9 then tate = true
    elseif id ~= 11 then abort(100, 0, "This TFM is not for Japanese.")
    end
    local nt, lf, lh, bc, ec, nw, nh, nd, ni, nl, nk, ng, np =
        unpack(tfm:unums(2, 13))
    sure(#tfm.data == lf * 4, 21)
    sure(bc == 0, 22)
    sure(7 + lh + nt + (ec - bc + 1) + nw + nh + nd + ni + nl + nk + ng + np
        == lf, 23)
    local header, char_type, char_info, width, height, depth =
        tfm:unums(4, lh), tfm:unums(4, nt), tfm:unums(4, ec + 1),
        tfm:unums(4, nw), tfm:unums(4, nh), tfm:unums(4, nd)
    tfm:str(ni * 4 + nl * 4 + nk * 4 + ng * 4) -- skip
    local param = tfm:unums(4, np)
    local unit, zw, zh = header[2], param[5], param[6]
    local ctype, cinfo = {}, {}
    sure(char_type[1] == 0, 24)
    for i = 2, #char_type do
      local cc, ti = bit_scan(char_type[i], 16, 16)
      ctype[cc] = ti
    end
    for ti = 0, #char_info-1 do
      local wi, hi, di, ii, tag, rem = 
        bit_scan(char_info[ti+1], 8, 4, 4, 6, 2, 8)
      cinfo[ti] = { wi = wi,
          wd = width[wi+1], ht = height[hi+1], dp = depth[di+1] }
    end
    local width_ = { unpack(width, 2) }
    -- lift the width of type 0 to position 0
    if cinfo[0].wi ~= 0 then
      local wi0 = cinfo[0].wi
      width_[0] = width_[wi0]
      for ti = 0, #char_info-1 do
        if cinfo[ti].wi == wi0 then
          width_[cinfo[ti].wi] = 0; cinfo[ti].wi = 0
        end
      end
    end
    -- done
    return {
      tate = tate, unit = unit, zw = zw, zh = zh,
      ctype = ctype, cinfo = cinfo, width = width_
    }
  end
  --- make_tfm(filename)
  -- Writes the fixed TFM.
  local raw_tfm =
    "\0\11\0\1\0\27\0\2\0\0\0\0\0\2\0\2\0\2\0\1\0\0\0\0\0\0\0\9\0\0\0\0"..
    "\0\160\0\0\0\0\0\0\1\17\0\0\0\0\0\0\0\16\0\0\0\0\0\0\0\14\102\102\0\0\0\0"..
    "\0\1\153\154\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\16\0\0\0\16\0\0"..
    "\0\0\0\0\0\0\0\0\0\0\0\0"
  function make_tfm(name)
    local fp = io.open(name..".tfm", "wb")
    if not fp then abort(100, 0, "I cannot create TFM file, %s.", name) end
    fp:write(raw_tfm)
    fp:close()
  end
end
---------------------------------------- codespace
do -- using generator pattern...
  local codespace_gen = {
    jis = function ()
      for r = 0x21, 0x7e do
        for c = 0x21, 0x7e do
          coroutine.yield(r * 0x100 + c)
        end
      end
    end;
    ucs = function ()
      for c = 0, 0xFFFF do
        coroutine.yield(c)
      end
    end;
    ucs3 = function ()
      for c = 0, 0x2FFFF do
        coroutine.yield(c)
      end
    end;
  }
  local function codespace_next(co, cur)
    local ok, nxt = coroutine.resume(co)
    return sure(ok, 2) and nxt
  end
  --- codespace(name)
  -- Returns the iterator (for generic FOR statements)
  function codespace(name)
    local co = coroutine.create(sure(codespace_gen[name], 2))
    return codespace_next, co, nil
  end
end
---------------------------------------- something VF
do
  local function numlen(v, s)
    if s then v = ((v < 0) and (-v - 1) or v) * 2 end
    return (v < 0x100) and 1 or (v < 0x10000) and 2 or
           (v < 0x1000000) and 3 or 4
  end
  local function vf_opcode(vf, opc, arg, s)
    local nl = numlen(arg, s)
    vf:setunum(1, opc - 1 + nl)
    return ((s) and vf.setsnum or vf.setunum)(vf, nl, arg)
  end
  local function vf_fontdef(vf, id, name, at)
    vf:setstr("\243"):setunum(1, id):setunum(4, 0)
        :setunum(4, at):setunum(4, 10*TU)
        :setunum(1, 0):setunum(1, #name):setstr(name)
  end
  local function vf_char(vf, cc, width, fid, right, down, occ)
    sure(fid < 256, 40)
    local vc = make_cdata("")
    vc:setstr("\242"):setunum(4, 0):setunum(4, cc):setunum(4, width)
    if right ~= 0 then
      vf_opcode(vc, 143, right, true) -- rightM
    end
    if down ~= 0 then
      vf_opcode(vc, 157, down, true) -- downM
    end
    if fid ~= 0 then
      if fid < 64 then vc:setunum(1, 171 + fid) -- fnt_num_N
      else vf_opcode(vc, 235, fid) -- fntM
      end
    end
    vf_opcode(vc, 128, occ) -- setM
    vc:pos(1):setunum(4, #vc.data - 13)
    vf:setstr(vc.data)
  end

  --- make_vf(filename, font_metric)
  function make_vf(name, fm)
    vf = make_cdata("")
    -- preamble
    vf:setstr("\247\202\0"):setunum(4, 0):setunum(4, 10*TU)
    -- fontdefs
    for id = 0, #fm.width do
      if fm.width[id] > 0 then
        vf_fontdef(vf, id, vtfmname, fm.width[id])
      end
    end
    -- char packets
    local csp = (ucs) and ((useset3) and "ucs3" or "ucs") or "jis"
    local ctype, cinfo, bsh, sm = fm.ctype, fm.cinfo, baseshift, snowman
    local bsd, bsl = (bsh.u - bsh.l) * fm.zh / 1000, bsh.l * fm.zh / 1000
    local cwd0 = cinfo[0].wd
    for cc in codespace(csp) do
      local glm1, glm2 = bit_scan(glemish(cc), 16, 16)
      local ti = ctype[cc] or 0; local cin = cinfo[ti]
      local right, down = 0, bsd * (glm1 / 65536) + bsl
      if cin.wd < cwd0 then -- narrow char
        down = down + (0.12 - temper(ti) / 100) * (cwd0 - cin.wd)
      end
      local smi = floor((glm2 / 65536) * #sm) + 1
      vf_char(vf, cc, cin.wd, cin.wi, right, down, sm[smi])
    end
    -- postamble
    vf:setstr(("\248"):rep(4 - #vf.data % 4))
    -- write it
    local fp = io.open(name, "wb")
    if not fp then abort(100, 0, "I cannot create VF file, %s.", name) end
    fp:write(vf.data)
    fp:close()
  end
end
---------------------------------------- logging
do
  function info(hd, ...)
    local t = { prog_name, hd, ... }
    if type(hd) == "number" then
      if hd == 0 then t = { string.format(...) }
      else t[2] = ("ERROR(%s)"):format(hd)
      end
    end
    io.stderr:write(concat(t, ": ").."\n")
  end
  function abort(stat, ...)
    info(...); os.exit(stat)
  end
  function sure(val, ...)
    if val then return val end
    abort(1, ...)
  end
end
---------------------------------------- main
do
  local ucs_param = {
    jis = 1; jisq = 1; gb = 1; cns = 1; ks = 1
  }
  local function is_sjis(stat)
    if os.type == "windows"
       or (os.getenv("OS") or ""):find("Windows") then
      local ok, res = pcall(function ()
        local pipe = assert(io.popen("chcp"))
        local l = pipe:read("*l") or ""; pipe:close()
        local _s, _e, cp = l:find("(%d+)$")
        return (tonumber(cp) == 932)
      end)
      return ok and res
    end
    return false
  end
  local function show_usage(stat)
    local sjis = is_sjis()
    io.stderr:write(([=[
%s version %s -- make Snowman VF file from a JFM file.
Usage:
%%%% %s [<options>] <TFMfile> <PSfontTFM>
]=]):format(prog_name:upper(), version, prog_name), [=[
  <TFMfile>:   Name of input pTeX/upTeX JFM file.
               The basename is inherited by the name of output VF file.
  <PSfontTFM>: Name of output PSfont JFM file.
Options:
-8 <number>  Unicode codepoint of the output character (snowman)
]=], ((sjis) and (
"-C           \146\183\145\204\131\130\129[\131h\n"..
"-K <PS-TFM>  \148\241\138\191\142\154\149\148\151p\130\201\141\236\144\172\130\183\130\233PS\131t\131H\131\147\131gTFM\150\188\n"..
"-b <\144\148\146l>    \131x\129[\131X\131\137\131C\131\147\149\226\144\179\n"..
"             \149\182\142\154\130\204\141\130\130\179\130\2401000\130\198\130\181\130\196\144\174\144\148\130\197\142w\146\232\n"..
"             \131v\131\137\131X\130\197\149\182\142\154\130\170\137\186\130\170\130\232\129A\131}\131C\131i\131X\130\197\149\182\142\154\130\170\143\227\130\170\130\233\n"..
"-m           \143c\143\145\130\171\142\158\130\201\131N\131I\129[\131g(\129f\129h)\130\204\145\227\130\237\130\232\130\201\131~\131j\131\133\129[\131g(\129\140\129\141)\130\240\142g\151p\n"..
"-a <AFMfile> AFM\131t\131@\131C\131\139\150\188\129i\130\169\130\200\139l\130\223\142\158\130\201\142g\151p\129j\n"..
"-k <\144\148\146l>    \130\169\130\200\139l\130\223\131}\129[\131W\131\147\142w\146\232\n"..
"             \149\182\142\154\149\157\130\2401000\130\198\130\181\130\196\144\174\144\148\130\197\142w\146\232\129B-a\131I\131v\131V\131\135\131\147\130\198\139\164\130\201\142g\151p\n"
) or [=[
-C           長体モード
-K <PS-TFM>  非漢字部用に作成するPSフォントTFM名
-b <数値>    ベースライン補正
             文字の高さを1000として整数で指定
             プラスで文字が下がり、マイナスで文字が上がる
-m           縦書き時にクオート(’”)の代わりにミニュート(′″)を使用
-a <AFMfile> AFMファイル名（かな詰め時に使用）
-k <数値>    かな詰めマージン指定
             文字幅を1000として整数で指定。-aオプションと共に使用
]=]), [=[
-i           Start mapped font ID from No. 0
-u <Charset> UCS mode
             <Charset> gb : GB,  cns : CNS,  ks : KS
                       jis : JIS,  jisq : JIS quote only
                       custom : Use user-defined CHARSET from <CNFfile>
Options below are effective only in UCS mode:
-J <PS-TFM>  Map single/double quote to another JIS-encoded PSfont TFM
-U <PS-TFM>  Map single/double quote to another UCS-encoded PSfont TFM
-3           Use set3, that is, enable non-BMP characters support
-H           Use half-width katakana
Inform bug reports at <https://github.com/zr-tex8r/SC-ripts/issues>.
]=])
    os.exit(stat)
  end
  local pat_tfm = "%.[Tt][Ff][Mm]$"
  local function basename(path)
    sure(type(path) == "string", 1)
    path = path:gsub("[\129-\159\224-\252]?.", { ["\\"] = "/" })
    return path:gsub(".*/", "")
  end
  local function with_ext(file, ext, forced)
    if not file then return file end
    local s = file:find("%.%w+$")
    if not s then return file.."."..ext
    elseif forced then return file:sub(1, s - 1).."."..ext
    else return file
    end
  end
  function read_option()
    local kanatume, afmname = -1 -- dummy params
    chotai = false; useset3 = false
    baseshift = "0"; snowman = "2603"
    if #arg == 0 then show_usage(0) end
    local err, idx = false, 1
    while idx <= #arg do
      if arg[idx]:sub(1, 1) ~= "-" then break end
      local opt = arg[idx]; idx = idx + 1
      local ii, oa = 2, nil
      while ii <= #opt do
        local oo = opt:sub(ii, ii); ii = ii + 1
        if ("KbakuJU8"):find(oo) then -- with arg
          if ii > #opt then
            oa = arg[idx]; idx = idx + 1; ii = #opt + 1
          else
            oa = opt:sub(ii); ii = #opt + 1
          end
          if not oa then
            info("option requires an argument -- " .. oo)
            err = true; break
          end
          if oo == "K" then     kanatfm = oa
          elseif oo == "b" then baseshift = oa
          elseif oo == "a" then afmname = oa
          elseif oo == "k" then kanatume = tonumber(oa) or 0
          elseif oo == "u" then
            if ucs_param[oa] then ucs = oa
            else info(0, "Charset is not set")
            end
          elseif oo == "J" then jistfm = oa
          elseif oo == "U" then ucsqtfm = oa
          elseif oo == "8" then snowman = oa
          end
        elseif oo == "C" then chotai = true
        elseif oo == "m" then -- minute = true
        elseif oo == "3" then useset3 = true
        elseif oo == "H" then -- hankana = true
        elseif oo == "i" then -- fidzero = true
        else info("invalid option -- "..oo); err = true; break
        end
      end
      if err then break end
    end
    if kanatume >= 0 and not afmname then
      abort(100, 0, "No AFM file for kanatume.")
    end
    if err or #arg - idx ~= 1 then
      show_usage(0)
    end
    atfmname = arg[idx]
    vfname = basename(arg[idx]):gsub(pat_tfm, "")..".vf"
    vtfmname = arg[idx + 1]:gsub(pat_tfm, "")
    kanatfm = kanatfm and kanatfm:gsub(pat_tfm, "")
    jistfm = jistfm and jistfm:gsub(pat_tfm, "")
    ucsqtfm = ucsqtfm and ucsqtfm:gsub(pat_tfm, "")
    local bs, sm = {}, {}
    for v in baseshift:gmatch("[^,]+") do
      table.insert(bs, tonumber(v) or 0)
    end
    baseshift = { l = math.min(unpack(bs)), u = math.max(unpack(bs)) }
    for v in snowman:gmatch("[^,]+") do
      table.insert(sm, tonumber(v, 16) or 0x2603)
    end
    snowman = sm
  end
  function main()
    read_option()
    local fm = get_tfm(atfmname)
    make_tfm(vtfmname)
    if kanatfm then make_tfm(kanatfm) end
    if jistfm then make_tfm(jistfm) end
    if ucsqtfm then make_tfm(ucsqtfm) end
    make_vf(vfname, fm)
  end
end
---------------------------------------- all done
main()
-- EOF
